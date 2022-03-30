variable "app_name" {
     type     = string
 }
 
 
 variable "module_name" {
     type     = string
 }

 variable "module_path" {
     type     = string
 }

 variable "source_branch" {
     type     = string
     default = "master"
 }

variable "environment_variables" {
  default = {}  
  type        = map(string)
}

variable "environment_variables_parameter_store" {
 type = map(string)
 default = {
 "ADO_USER" = "/app/ado_user"
 "ADO_PASSWORD" = "/app/ado_password"
 }
}

variable "privileged_mode" { 
    type        = bool
    default     = true
    description = "set to true if building a docker"
}
