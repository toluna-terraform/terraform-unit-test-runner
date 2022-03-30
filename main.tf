locals{
    codebuild_name = "${var.app_name}-test-${var.module_name}"
    codebuild_release_name = "${var.app_name}-release-${var.module_name}"  
    parsed_module_path = trimprefix(trimsuffix(var.module_path,".git"), "https://")
}

resource "aws_codebuild_source_credential" "pr_flow_hook_webhook" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = "${data.aws_ssm_parameter.github_token.value}"
}

resource "aws_codebuild_webhook" "pr_flow_hook_webhook" {
  project_name = aws_codebuild_project.codebuild_release.name
  build_type   = "BUILD"
  filter_group {
    filter {
      exclude_matched_pattern = false
      pattern                 = "master"
      type                    = "BASE_REF"
    }
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED, PULL_REQUEST_UPDATED, PULL_REQUEST_REOPENED"
    }
  }
}

resource "aws_codebuild_source_credential" "merge_flow_hook_webhook" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = "${data.aws_ssm_parameter.github_token.value}"
}

resource "aws_codebuild_webhook" "merge_flow_hook_webhook" {
  project_name = aws_codebuild_project.codebuild_merge.name
  build_type   = "BUILD"
  filter_group {
    filter {
      exclude_matched_pattern = false
      pattern                 = "master"
      type                    = "BASE_REF"
    }
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_MERGED"
    }
  }
}

resource "aws_codebuild_project" "codebuild_release" {
  name          = "${local.codebuild_name}"
  description   = "Build spec for ${local.codebuild_name}"
  build_timeout = "120"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type           = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    dynamic "environment_variable" {
      for_each = var.environment_variables
      
      content {
        name                 = environment_variable.key
        value                = environment_variable.value
      }

    }
      dynamic "environment_variable" {
        for_each = var.environment_variables_parameter_store
        
        content {
          name                 = environment_variable.key
          value                = environment_variable.value
          type                 = "PARAMETER_STORE"
        }

      }

      privileged_mode = var.privileged_mode  
  }

  source {
    type            = "GITHUB"
    location        = var.module_path
    git_clone_depth = 1
    report_build_status = true
    buildspec = templatefile("${path.module}/templates/test_buildspec.yml.tpl", { MODULE_NAME = var.module_name, MODULE_PATH = local.parsed_module_path })
  }
   
    tags = tomap({
                Name="codebuild-${local.codebuild_name}",
                created_by="terraform"
    })
}


resource "aws_codebuild_project" "codebuild_merge" {
  name          = "${local.codebuild_release_name}"
  description   = "Build spec for ${local.codebuild_release_name}"
  build_timeout = "120"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type           = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    dynamic "environment_variable" {
      for_each = var.environment_variables
      
      content {
        name                 = environment_variable.key
        value                = environment_variable.value
      }

    }
      dynamic "environment_variable" {
        for_each = var.environment_variables_parameter_store
        
        content {
          name                 = environment_variable.key
          value                = environment_variable.value
          type                 = "PARAMETER_STORE"
        }

      }

      privileged_mode = var.privileged_mode  
  }

  source {
    type            = "GITHUB"
    location        = var.module_path
    git_clone_depth = 1
    report_build_status = true
    buildspec = templatefile("${path.module}/templates/release_buildspec.yml.tpl", { MODULE_NAME = var.module_name, MODULE_PATH = local.parsed_module_path })
  }
   
    tags = tomap({
                Name="codebuild-${local.codebuild_release_name}",
                created_by="terraform"
    })
}

resource "aws_iam_role" "codebuild_role" {
  name = "role-${local.codebuild_name}"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "source_codebuild_iam_policy" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
