version: 0.2

env:
  parameter-store:
    GITHUB_TOKEN: "/app/github_token"

phases:
  install:
    runtime-versions:
      docker: 18
  pre_build:
    commands:
      - yum -y install yum-utils
      - wget -O /usr/local/bin/semver https://raw.githubusercontent.com/toluna-terraform/scripts/master/release-management/semver
      - chmod +x /usr/local/bin/semver
  build:
    commands:
      - |
        prefix="git@github.com:"
        repo_full_name=$(git config --get remote.origin.url | sed 's/.*:\/\/github.com\///;s/.git$//')
        repo_full_name=$${repo_full_name#"$prefix"}
        LATEST_TAG=$(curl -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$repo_full_name/releases/latest" | jq -r '.tag_name')
        export NEW_VERSION=$(semver bump patch $LATEST_TAG)
        echo "Create release $NEW_VERSION for repo: $repo_full_name branch: master"
        COMMIT_ID=$${CODEBUILD_RESOLVED_SOURCE_VERSION:0:7}
        curl -X POST "https://api.github.com/repos/$repo_full_name/releases" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -d "{\"tag_name\": \"$NEW_VERSION\",\"target_commitish\": \"master\",\"name\": \"$NEW_VERSION\",\"body\": \"Release automatically created from commit id: $COMMIT_ID\",\"draft\": false,\"prerelease\": false }"


  
