// DigitalOcean
variable "do_token" {}
variable "do_cluster_name" {}
variable "do_access_id" {}
variable "do_secret_key" {}
variable "do_space_name" {}

// DataDog
variable "dd_api_key" {}

// Cloudflare - Bsord
//variable "cloudflare_email_bsord" {}
//variable "cloudflare_api_key_bsord" {}
//variable "cloudflare_zone_id_bsord_io" {}

// Cloudflare - Fairbanks
variable "cloudflare_email_fairbanks" {}
variable "cloudflare_api_key_fairbanks" {}
variable "cloudflare_zone_id_fairbanks_dev" {}
variable "cloudflare_zone_id_fairbanks_io" {}
variable "cloudflare_zone_id_fbnks_dev" {}
variable "cloudflare_zone_id_fbnks_io" {}

// Flux
variable "grafana_password" {}
variable "flux_deploy_key" {}

//Sealed Secrets
variable "sealed_sec_pub" {}
variable "sealed_sec" {}