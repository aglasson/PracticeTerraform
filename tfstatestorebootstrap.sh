# This will create the defined resources if not already present and ensure their configuration is as defined.

az group create --location westus --resource-group rg-tp-tfstate
az storage account create --name sttpstatestore --resource-group rg-tp-tfstate --location westus --sku Standard_LRS --allow-shared-key-access false --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create --name tfstate --account-name sttpstatestore --auth-mode login
