variable "resource_group_name" {
    description = "The name of the resource group"
    type        = string    
}
variable "location" {
    description = "The location where resources will be created"
    type        = string  
}
variable "environment" {
    description = "The deployment environment (e.g., dev, prod)"
    type        = string
}

variable "subnet_ids" {
    description = "The ID of the subnet for security rules"
    type        = list(string)
  
}

variable "subnet_prefixes" {
    description = "The address prefixes for the subnet"
    type        = map(string)
}

variable "public_ip" {
    description = "The public IP resource for the security module"
    type        = any 
}

variable "pip_id" { 
    description = "The ID of the public IP"
    type        = any
}

