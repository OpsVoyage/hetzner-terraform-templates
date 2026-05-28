terraform {
  backend "s3" {
    bucket = "1b927859-f1ce-4ea9-b5f6-57059506ea83-opsvoyage-backends"
    key    = "4b5c2cae-6157-4ca4-afcb-06d102fa7afc/terraform.tfstate"
    region = "eu-central-1"
  }
}
