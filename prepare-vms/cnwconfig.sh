if [ $# -eq 0 ]
then
	echo "A shell script to configure nodes for a kubernetes workshop."
	echo "Usage : $0 name of workshop"
	exit 1
fi

./workshopctl deploy $1 settings/workshop-settings.yaml
./workshopctl pull_images $1
./workshopctl kube $1
./workshopctl cards $1 settings/workshop-settings.yaml