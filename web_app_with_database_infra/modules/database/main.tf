



resource "azurerm_mysql_flexible_server" "msdb" {
    name                   = "mysql-${var.environment}"
    location               = var.location
    resource_group_name    = var.resource_group_name
    administrator_login    = var.administrator_login
    administrator_password = var.administrator_password
    version                = "5.7"
    sku_name               = "Standard_B1ms"
}


resource "azurerm_mysql_flexible_database" "mysfdb" {
    name                = "mysqldb-${var.environment}"
    resource_group_name = var.resource_group_name
    server_name         = azurerm_mysql_flexible_server.msdb.name
    charset             = "utf8"
    collation           = "utf8_general_ci"
}

 