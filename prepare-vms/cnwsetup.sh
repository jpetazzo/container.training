export WORKSHOPNAME=$1
cd prepare-vms
docker-compose build
az group create --name $WORKSHOPNAME --location eastus
az group deployment create --resource-group $WORKSHOPNAME --template-file azuredeploy.json --parameters @azuredeploy.parameters.json
az vm list-ip-addresses --resource-group $WORKSHOPNAME --output table
mkdir -p tags/$WORKSHOPNAME
az vm list-ip-addresses --resource-group $WORKSHOPNAME --output json | jq -r '.[].virtualMachine.network.publicIpAddresses[].ipAddress' > tags/$WORKSHOPNAME/ips.txt
# az group delete --resource-group $WORKSHOPNAME -y