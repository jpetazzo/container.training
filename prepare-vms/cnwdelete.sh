#!/bin/bash

if [ $# -eq 0 ]
then
	echo "A shell script to spin up workshops."
	echo "Usage : $0 number"
	exit 1
fi

if [ "$1" -lt 1 ]
then
	echo "Min amount of clusters is 1"
	exit 1
fi

if [ "$1" -gt 172 ]
then
	echo "Max amount of clusters is 172"
	exit 1
fi

declare -a arr=("Aberaeron" "Aberavon" "Aberbargoed" "Abercarn" "Abercwmboi" "Aberdare" "Abergavenny" "Abergele" "Aberporth" "Abertillery" "Aberystwyth" "Afonwen" "Amlwch" "Ammanford" "Argoed" "Bagillt" "Bala" "Bangor" "Bargoed" "Barmouth" "Barry" "Beaumaris" "Bedwas" "Benllech" "Bethesda" "BlaenauFfestiniog" "Blaenavon" "Blackwood" "Blaina" "Brecon" "Bridgend" "BritonFerry" "Brynmawr" "Buckley" "BuilthWells" "BurryPort" "Caerleon" "Caernarfon" "Caerphilly" "Caerwys" "Caldicot" "Cardiff" "Cardigan" "Carmarthen" "Chepstow" "Chirk" "Cilgerran" "ColwynBay" "ConnahsQuay" "Conwy" "Corwen" "Cowbridge" "Criccieth" "Crickhowell" "Crumlin" "Cwmamman" "Cwmbran" "Denbigh" "Dolgellau" "EbbwVale" "Ewloe" "Ferndale" "Ffestiniog" "Fishguard" "Flint" "Gelligaer" "Glynneath" "Goodwick" "Gorseinon" "Gresford" "Hakin" "Harlech" "Haverfordwest" "HayOnWye" "Holt" "Holyhead" "Holywell" "Kidwelly" "Knighton" "Lampeter" "Laugharne" "Llanberis" "Llandeilo" "Llandovery" "LlandrindodWells" "Llandudno" "LlandudnoJunction" "Llanddulas" "Llandysul" "Llanelli" "LlanfairCaereinion" "Llanfairfechan" "Llanfyllin" "Llangefni" "Llangollen" "Llanidloes" "Llanrwst" "Llantrisant" "LlantwitMajor" "LlanwrtydWells" "Llanybydder" "Loughor" "Machynlleth" "Maesteg" "MenaiBridge" "MerthyrTydfil" "MilfordHaven" "Mold" "Monmouth" "Montgomery" "MountainAsh" "MaesglasMiskin" "Narberth" "Neath" "Nefyn" "Newbridge" "NewcastleEmlyn" "Newport" "NewQuay" "Newtown" "Neyland" "OldColwyn" "OldRadnor" "OvertonOnDee" "Pembroke" "PembrokeDock" "Penarth" "Pencoed" "Penmaenmawr" "PenrhynBay" "Pontardawe" "Pontarddulais" "Pontyclun" "Pontypool" "Pontypridd" "PortTalbot" "Porth" "Porthcawl" "Porthmadog" "Prestatyn" "Presteigne" "Pwllheli" "Queensferry" "Rhayader" "Rhuddlan" "Rhyl" "Rhymney" "Risca" "Ruthin" "StAsaph" "StClears" "StDavids" "Senghenydd" "Saltney" "Shotton" "Swansea" "Talgarth" "Templeton" "Tenby" "Tonypandy" "Tredegar" "Tregaron" "Treharris" "Treorchy" "Tywyn" "Usk" "Welshpool" "Whitland" "Wrexham" "Ystradgynlais" "YstradMynach" "Ynysddu")

for ((i=0;i<$1;i++)); do
	{
		echo "Deleting" ${arr[i]}
        az group delete --resource-group ${arr[i]} -y
        rm -rf ./tags/${arr[i]}
		echo ${arr[i]} "complete"
	} &
done