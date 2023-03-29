# borrowed from https://gist.github.com/kirikaza/6627072
# The original script has been wrapped in a function that invokes a subshell.
# That way, it can be safely invoked as a function from other scripts.

find_ubuntu_ami() {
    (

        usage() {
            cat >&2 <<__
usage: find-ubuntu-ami.sh [ <filter>... ] [ <sorting> ] [ <options> ]
where:
    <filter> is pair of key and substring to search
        -r <region>
        -n <name>
        -v <version>
        -a <arch>
        -t <type>
        -d <date>
        -i <image>
        -k <kernel>
    <sorting> is one of:
        -R   by region 
        -N   by name 
        -V   by version 
        -A   by arch 
        -T   by type 
        -D   by date 
        -I   by image 
        -K   by kernel 
    <options> can be:
        -q   just show AMI

    protip for Docker orchestration workshop admin:
        ./find-ubuntu-ami.sh -t hvm:ebs -r \$AWS_REGION -v 15.10 -N
__
            exit 1
        }

        args=$(getopt hr:n:v:a:t:d:i:k:RNVATDIKq $*)
        if [ $? != 0 ]; then
            echo >&2
            usage
        fi

        region=
        name=
        version=
        arch=
        type=
        date=
        image=
        kernel=

        sort=date

        quiet=

        set -- $args
        for a; do
            case "$a" in
            -h) usage ;;

            -r)
                region=$2
                shift
                ;;
            -n)
                name=$2
                shift
                ;;
            -v)
                version=$2
                shift
                ;;
            -a)
                arch=$2
                shift
                ;;
            -t)
                type=$2
                shift
                ;;
            -d)
                date=$2
                shift
                ;;
            -i)
                image=$2
                shift
                ;;
            -k)
                kernel=$2
                shift
                ;;

            -R) sort=region ;;
            -N) sort=name ;;
            -V) sort=version ;;
            -A) sort=arch ;;
            -T) sort=type ;;
            -D) sort=date ;;
            -I) sort=image ;;
            -K) sort=kernel ;;

            -q) quiet=y ;;

            --)
                shift
                break
                ;;
            *) continue ;;
            esac
            shift
        done

        [ $# = 0 ] || usage

        fix_json() {
            tr -d \\n | sed 's/,]}/]}/'
        }

        jq_query() {
            cat <<__
    .aaData | map (
        {
            region: .[0],
            name: .[1],
            version: .[2],
            arch: .[3],
            type: .[4],
            date: .[5],
            image: .[6],
            kernel: .[7]
        } | select (
            (.region | contains("$region")) and
            (.name | contains("$name")) and
            (.version | contains("$version")) and
            (.arch | contains("$arch")) and
            (.type | contains("$type")) and
            (.date | contains("$date")) and
            (.image | contains("$image</a>")) and
            (.kernel | contains("$kernel"))
        )
    ) | sort_by(.$sort) | .[] |
    "\(.region)|\(.name)|\(.version)|\(.arch)|\(.type)|\(.date)|\(.image)|\(.kernel)"
__
        }

        trim_quotes() {
            sed 's/^"//;s/"$//'
        }

        escape_spaces() {
            sed 's/ /\\\ /g'
        }

        url=http://cloud-images.ubuntu.com/locator/ec2/releasesTable

        {
            [ "$quiet" ] || echo REGION NAME VERSION ARCH TYPE DATE IMAGE KERNEL
            curl -s $url | fix_json | jq "$(jq_query)" | trim_quotes | escape_spaces | tr \| ' '
        } \
            | while read region name version arch type date image kernel; do
                image=${image%<*}
                image=${image#*>}
                if [ "$quiet" ]; then
                    echo $image
                else
                    echo "$region|$name|$version|$arch|$type|$date|$image|$kernel"
                fi
            done | column -t -s \|

    )
}
