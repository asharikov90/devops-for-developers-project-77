terraform {
  required_version = ">= 1.5.3"

  required_providers {
    twc = {
      source  = "tf.timeweb.cloud/timeweb-cloud/timeweb-cloud"
      version = "~> 1.7"
    }
  }
}

provider "twc" {}
