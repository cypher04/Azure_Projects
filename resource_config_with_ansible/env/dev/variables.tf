variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  
}

variable "location" {
  description = "The Azure region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}
  
variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource group"
  type        = map(string)
  default     = {}
}
