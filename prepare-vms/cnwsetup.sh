if [ $# -eq 0 ]
then
	echo "A shell script to configure nodes for a kubernetes workshop."
	echo "Usage : $0 name of workshop"
	exit 1
fi

az group create --name $1 --location eastus
az group deployment create --resource-group $1 --template-file azuredeploy.json --parameters @azuredeploy.parameters.json
az vm list-ip-addresses --resource-group $1 --output table
mkdir -p tags/$1
az vm list-ip-addresses --resource-group $1 --output json | jq -r '.[].virtualMachine.network.publicIpAddresses[].ipAddress' > tags/$1/ips.txt