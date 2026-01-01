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

variable "subnet_ids" {
    description = "A list of subnet IDs"
    type        = list(string)
}

variable "monitoring_workspace_name" {
    description = "The name of the monitoring workspace"
    type        = string
    default     = "monitoring-ws"
}



variable "virtual_machine_scale_set_id" {
    description = "A list of virtual machine scale set IDs to monitor"
    type        = list(string)
}


