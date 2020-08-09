#!/bin/bash

#####################################################################
# Usage
function print_usage {    
    local me=`basename "$0"`

    if ! [ -z ${1+x} ]; then # If it is set.
        echo "Missing required option $1"
    fi

    echo "Usage: $me [-d domainname] [-n stackname] ?[-s snapshotid] ?[-v]"
    echo "  -d domainname (required) e.g. -d xyz.com"
    echo "  -n stackname (required) e.g. -n xyz-com"
    echo "  -s snapshotid (optional) e.g. -s snap-123"
    echo "  -v create volume directories (optional) e.g. -v"
}

POSITIONAL=()
while [ $# -gt 0 ];
do
key="$1"

case $key in
    -d|--domainname)
    DOMAIN_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--stackname)
    STACK_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--snapshotid)
    SNAPSHOT_ID="$2"
    shift # past argument
    shift # past value
    ;;
    -v|--volumedirs)
    CREATE_VOLUME_DIRECTORIES="1" # This is a flag.
    shift # past argument
    shift # past value
    ;;
    --help)
    shift # past argument
    print_usage
    exit 0
    ;;
    *)    # unknown option
    #POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    echo "Unknown option $key"
    print_usage
    exit 0
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Check required options are set

if [ -z ${DOMAIN_NAME} ]; then # If it is unset.
    print_usage "-d"
    exit 1
fi

if [ -z ${STACK_NAME} ]; then # If it is unset.
    print_usage "-n"
    exit 1
fi

SCRIPT_ROOT=https://raw.githubusercontent.com/software-pek-com/scripts/master

#####################################################################
# Functions

function create_bootstrap_log {
    echo "DomainName: ${DOMAIN_NAME}" >> boostrap.log
    echo "StackName: ${STACK_NAME}" >> boostrap.log
    echo "SnapshotId: ${SNAPSHOT_ID}" >> boostrap.log
    echo "VolumeDirs: ${CREATE_VOLUME_DIRECTORIES}" >> boostrap.log
    # echo "DomainName: ${DOMAIN_NAME}"
    # echo "StackName: ${STACK_NAME}"
    # echo "SnapshotId: ${SNAPSHOT_ID}"
    # echo "VolumeDirs: '${CREATE_VOLUME_DIRECTORIES}'"
}

function mount_snapshot {
    if ! [ -z ${SNAPSHOT_ID} ]; then # If it is set.
        mkdir /mnt/${SNAPSHOT_ID}
        mkfs.xfs /dev/xvdf
        echo "/dev/xvdf	/mnt/${SNAPSHOT_ID}	auto	defaults,nofail	0	2" >> /etc/fstab
        mount -a
        ln -s /mnt/${SNAPSHOT_ID} /mnt/${STACK_NAME}
    fi
}

function update_and_install {
    apt-get -y update
    apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        docker-compose \
        gnupg-agent \
        software-properties-common
        
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get -y install docker-ce docker-ce-cli containerd.io
    usermod -aG docker ubuntu
}

function bootstrap_docker_tls {
    curl https://raw.githubusercontent.com/software-pek-com/scripts/master/docker/bootstrap-docker-tls.sh > /tmp/bootstrap-docker-tls.sh
    chmod 755 /tmp/bootstrap-docker-tls.sh
    /tmp/bootstrap-docker-tls.sh -d ${DOMAIN_NAME} -n ${STACK_NAME}
    rm -f /tmp/c-docker-tls.sh
}

function create_volume_directories {
    if ! [ -z ${CREATE_VOLUME_DIRECTORIES+x} ]; then # If it is set.
        curl ${SCRIPT_ROOT}/docker/create-volume-directories.sh > create-volume-directories.sh

        chmod 755 create-volume-directories.sh
        ./create-volume-directories.sh -d ${DOMAIN_NAME} -p /mnt/${STACK_NAME}
    fi
}

#####################################################################
# Body

create_bootstrap_log
# exit 0;

mount_snapshot
update_and_install
create_volume_directories

# exit 0;