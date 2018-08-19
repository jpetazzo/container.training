export WORKSHOPNAME=$1
./workshopctl deploy $WORKSHOPNAME settings/workshop-settings.yaml
./workshopctl pull_images $WORKSHOPNAME
./workshopctl cards $WORKSHOPNAME settings/workshop-settings.yaml
./workshopctl list
./workshopctl list $WORKSHOPNAME
# ./workshopctl stop $WORKSHOPNAME