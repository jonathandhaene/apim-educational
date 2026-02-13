# Diagnostics Module Variables
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "base_name" { type = string }
variable "environment" { type = string }
variable "retention_in_days" { type = number }
variable "tags" { type = map(string) }
