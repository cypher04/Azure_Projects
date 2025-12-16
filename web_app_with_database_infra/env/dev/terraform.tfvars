resource_group_name = "rg-webapp-dev"
location            = "East US"
environment         = "dev"
administrator_login = "sqladminuser"
administrator_password = "P@ssw0rd1234!"
address_space       = ["10.0.0.0/16"]
subnet_prefixes = {
    web = "10.0.1.0/24",  # web subnet
    database = "10.0.2.0/24",  # database subnet
    management = "10.0.3.0/24"   # management subnet
}