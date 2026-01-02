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


variable "administrator_login" {
  description = "The administrator username for the virtual machine"
  type        = string
}

variable "administrator_password" {
  description = "The administrator password for the virtual machine"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "The file path to the SSH public key"
  type        = string
}


variable "subnet_ids" {
  description = "A list of subnet IDs for the virtual machine scale set"
  type        = list(string)
}

variable "load_balancer_backend_address_pool_id" {
  description = "The ID of the load balancer backend address pool"
  type        = string
}