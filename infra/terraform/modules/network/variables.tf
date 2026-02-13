# Network Module Variables
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "base_name" { type = string }
variable "environment" { type = string }
variable "vnet_type" { type = string }
variable "vnet_address_space" { type = list(string) }
variable "subnet_address_prefix" { type = string }
variable "tags" { type = map(string) }
