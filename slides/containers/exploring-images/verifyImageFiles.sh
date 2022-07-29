
fileContentsCompare() {
    layer=$1
    text=$2
    file=$(pwd)/$3

    if [ -f "$file" ]; then

        fileContents=$(cat $file)

        if [ "$fileContents" != "$text" ]; then
            echo In Layer $layer Unexpected contents in file: $file
            echo -- Contents: $fileContents
            echo -- Expected: $text
        fi
    else 
        echo Missing File $file in Layer $layer
    fi
}

checkLayer() {
    layer=$1

    find . >/tmp/state


    if [[ $(diff /tmp/state $targetDir/../state.layer-$layer) ]]; then
      echo Directory Structure mismatch in layer: $layer 
      diff /tmp/state $targetDir/../state.layer-$layer
    fi

    case $layer in
        0)
            fileContentsCompare $layer "A is for Aardvark" A
            fileContentsCompare $layer "B is for Beetle" B
            fileContentsCompare $layer "A is for Cowboy Allan" C/CA
            fileContentsCompare $layer "A is for Cowboy Buffalo Alex" C/CB/CBA
            fileContentsCompare $layer "B is for Cowboy Buffalo Bill" C/CB/CBB
            fileContentsCompare $layer "Z is for Cowboy Zeke"  C/CZ
            fileContentsCompare $layer "A is for Detective Alisha" D/DA
            fileContentsCompare $layer "B is for Detective Betty" D/DB
            fileContentsCompare $layer "E is for Elephant" E
            ;;

        # echo "== LAYER 1 ==  Change File B, Create File C/CC, Add Dir C/CD, Remove File E, Create Dir F, Add File G, Create Empty Dir H"
        1)
            fileContentsCompare $layer "A is for Aardvark" A
            fileContentsCompare $layer "B is for Butterfly" B                       ## CHANGED FILE B
            fileContentsCompare $layer "A is for Cowboy Allan" C/CA
            fileContentsCompare $layer "A is for Cowboy Buffalo Alex" C/CB/CBA
            fileContentsCompare $layer "B is for Cowboy Buffalo Bill" C/CB/CBB
            fileContentsCompare $layer "C is for Cowboy Chuck" C/CC                 ## ADDED FILE C/CC
            fileContentsCompare $layer "A is for Cowboy Dandy Austin" C/CD/CDA      ## ADDED DIR C/CD, ADDED FILE C/CD/CDA
            fileContentsCompare $layer "Z is for Cowboy Zeke"  C/CZ
            fileContentsCompare $layer "A is for Detective Alisha" D/DA
            fileContentsCompare $layer "B is for Detective Betty" D/DB
                                                                                    ## REMOVED FILE E
            fileContentsCompare $layer "A is for Ferret Albert" F/FA                ## ADDED DIR F, ADDED FILE F/A
            fileContentsCompare $layer "G is for Gorilla" G                         ## ADDED G
                                                                                    ## CREATED EMPTY DIR H
            ;;

        # echo "== LAYER 2 ==  Remove File C/CA, Remove Dir C/CB, Remove Dir C/CB, Remove Dir D Replace with new Dir D, Delete and Recreatee File G, Add File H/HA Create Dir I"
        2)  
            fileContentsCompare $layer "A is for Aardvark" A
            fileContentsCompare $layer "B is for Butterfly" B
                                                                                    ## REMOVED FILE C/CA
                                                                                    ## REMOVED DIR C/CB
            fileContentsCompare $layer "C is for Cowboy Chuck" C/CC
            fileContentsCompare $layer "A is for Cowboy Dandy Austin" C/CD/CDA
            fileContentsCompare $layer "Z is for Cowboy Zoe"  C/CZ                     ## CHANGED FILE C/CZ
                                                                                    ## REMOVE DIR D
            fileContentsCompare $layer "A is for Duplicitous Albatros" D/DA         ## RECREATE DIR D, ADD FILE D/DA
            fileContentsCompare $layer "G is for Geccos" G                          ## DELETED FILE G, ADDED FILE G (Implicit CHANGED)
            fileContentsCompare $layer "H is for Human"  H                          ## ADDED FILE H
            ;;

    esac 
}



layer=$1
targetDir=$2

echo VERIFYING LAYER $layer

checkLayer $layer