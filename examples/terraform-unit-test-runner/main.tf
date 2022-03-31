module "unit-tester" {
    for_each = jsonencode({"terraform-unit-test-runner" : {"location": "https://github.com/toluna-terraform/terraform-unit-test-runner.git"}})
    source = "../../"
    app_name = "example_runner"
    module_name = "${each.key}"
    module_path = "${each.value.location}"
}