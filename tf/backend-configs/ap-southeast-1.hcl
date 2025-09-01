bucket         = "yagr-tfstate-log-us"
key            = "observability-demo/dev/ap-southeast-1/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
