bold() { 
    msg=$1 
    echo "$(tput bold)$1$(tput sgr0)" 
} 
 
green() { 
    msg=$1 
    echo "$(tput setaf 2)$1$(tput sgr0)" 
} 
 
yellow(){ 
    msg=$1 
    echo "$(tput setaf 3)$1$(tput sgr0)" 
} 

