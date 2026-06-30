terraform {
  backend "s3" {
    key                         = "states/devops-for-developers-project-77.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
