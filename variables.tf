variable "resource_group_name" {
  type        = string
  description = "azaksrgwus3"
}
variable "location" {
  type        = string
  description = "westus3"
}
variable "cluster_name" {
  type        = string
  description = "azAKS2504"
}
variable "kubernetes_version" {
  type        = string
  description = "1.24.0"
}
variable "system_node_count" {
  type        = number
  description = "1"
}
variable "acr_name" {
  type        = string
  description = "azACR2504"
}
