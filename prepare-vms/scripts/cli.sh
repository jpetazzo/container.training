die () {
    if [ -z "$1" ]; then
        exit 1
    fi
    echo -n $(tput setaf 1)
    echo -e "$1"
    echo -n $(tput sgr0)
    exit 1
}

need_tag(){
    TAG=$1
    if [ -z "$TAG" ]; then
        echo "Please specify a tag. Here's the list: "
        aws_display_tags
        die
    fi
}

need_token(){
    TOKEN=$1
    if [ -z "$TOKEN" ]; then
        echo "Please specify a token. Here's the list: "
        aws_display_tokens
        die
    fi
}

need_ips_file() {
    IPS_FILE=$1
    if [ -z "$IPS_FILE" ]; then
        echo "IPS_FILE not set."
        die
    fi

    if [ ! -s "$IPS_FILE" ]; then
        echo "IPS_FILE $IPS_FILE not found. Please run: trainer ips <TAG>"
        die
    fi
}
