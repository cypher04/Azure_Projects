resource "azurerm_monitor_autoscale_setting" "asmonitoring" {
  name                = "${var.project_name}-as-monitoring-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = var.virtual_machine_scale_set_id[0]

  profile {
    name = "defaultProfile" 

    capacity {
      minimum = "1"
      maximum = "5"
      default = "1"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.virtual_machine_scale_set_id[0]
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
        dimensions {
            name  = "VMSSName"
            values = ["App1"]
            operator = "Equals"
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.virtual_machine_scale_set_id[0]
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = []
    }
  }
  
}

