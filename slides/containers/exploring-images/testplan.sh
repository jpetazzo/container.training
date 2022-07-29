clear

baseDir=$(pwd)

rm -rf /tmp/exploringImags

mkdir -p /tmp/exploringImags

cd /tmp/exploringImags


echo "== LAYER 0 =="

echo "A is for Aardvark" >A
echo "B is for Beetle" >B

mkdir C/
echo "A is for Cowboy Allan" >C/CA

mkdir -p C/CB
echo "A is for Cowboy Buffalo Alex" >C/CB/CBA
echo "B is for Cowboy Buffalo Bill" >C/CB/CBB

echo "Z is for Cowboy Zeke" >C/CZ

mkdir D/
echo "A is for Detective Alisha" >D/DA
echo "B is for Detective Betty" >D/DB

echo "E is for Elephant" >E

find . >../state.layer-0
tree | grep -v directories | tee ../tree.layer-0

$baseDir/verifyImageFiles.sh 0 $(pwd)


echo "== LAYER 1 ==  Change File B, Create File C/CC, Add Dir C/CD, Remove File E, Create Dir F, Add File G, Create Empty Dir H"

echo "B is for Butterfly" >B

echo "C is for Cowboy Chuck">C/CC

mkdir -p C/CD
echo "A is for Cowboy Dandy Austin" >C/CD/CDA

rm E

mkdir F
echo "A is for Ferret Albert" >F/FA 

echo "G is for Gorilla" >G

mkdir H

find . >../state.layer-1
tree | grep -v directories | tee ../tree.layer-1

$baseDir/verifyImageFiles.sh 1 $(pwd)


echo "== LAYER 2 ==  Remove File C/CA, Remove Dir G, Remove Dir D Replace with new Dir D, Remove Dir C/CB, Remove Dir C/CB, Add File H/HA, Add File, Create Dir I"

rm C/CA 

rm -rf C/CB

echo "Z is for Cowboy Zoe" >C/CZ

rm -rf D
mkdir -p D
echo "A is for Duplicitous Albatros" >D/DA

rm -rf F

rm -rf G
echo "G is for Geccos" >G

rmdir H
echo "H is for Human" >H


find . >../state.layer-2
tree | grep -v directories | tee ../tree.layer-2

$baseDir/verifyImageFiles.sh 2 $(pwd)

