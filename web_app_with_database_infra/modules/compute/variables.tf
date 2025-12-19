variable "location" {

    description = "The location where resources will be created"
    type        = string
    }

variable "resource_group_name" {
    description = "The name of the resource group"
    type        = string    
    }

variable "environment" {
    description = "The deployment environment (e.g., dev, prod)"
    type        = string
    }   

variable "subnet_id" {
    description = "The ID of the subnet where the compute resources will be deployed"
    type        = string
    }

variable "administrator_login" {
    description = "The administrator login for the SQL server"
    type        = string
}

variable "administrator_password" {
    description = "The administrator password for the SQL server"
    type        = string
}

# variable "subnet_prefixes" {
#     description = "The address prefixes for the subnet"
#     type        = map(string)
# }


variable "mssql_server_name" {
    description = "The name of the MSSQL Server"
    type        = string
}

variable "mssql_db_name" {
    description = "The name of the MSSQL Database"
    type        = string
}

# variable "mssql_server_id" {
#     description = "The ID of the MSSQL Server"
#     type        = string
# }

variable "mssql_server_id" {
    description = "The ID of the MSSQL Server"
    type        = any
}