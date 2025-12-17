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

variable "administrator_login" {
    description = "The administrator login for the database"
    type        = string            
}   
variable "administrator_password" {
    description = "The administrator password for the database"
    type        = string
    sensitive   = true 
}

variable "address_space" {
    description = "The address space for the virtual network"
    type        = list(string)
}

variable "subnet_prefixes" {
    description = "The address prefixes for the subnet"
    type        = list(string)
}




