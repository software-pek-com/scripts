#!/bin/bash

#####################################################################
# Usage
function print_usage {    
    local me=`basename "$0"`
    echo "usage: $me [-d domainname] [-n stackname] [-s snapshotid] [-v]"
    echo "  -d domainname (required) e.g. -d xyz.com"
    echo "  -n stackname (required) e.g. -n xyz-com"
    echo "  -s snapshotid (optional) e.g. -s snap-123"
    echo "  -v create volume directories (optional) e.g. -v"
}

# We need 3 options with values so there must be 6 script arguments
if [ $# -ne 6 ]; then
    print_usage
    exit 1
fi

while getopts "d:n:s:v" OPTION; do
    case ${OPTION} in
    d)
        DOMAIN_NAME=${OPTARG}
        if [ -z ${DOMAIN_NAME} ]; then
            print_usage
            exit 1
        fi
        ;;
    n)
        STACK_NAME=${OPTARG}
        if [ -z ${STACK_NAME} ]; then
            print_usage
            exit 1
        fi
        ;;
    s)
        SNAPSHOT_ID=${OPTARG}
        if [ -z ${SNAPSHOT_ID} ]; then
            print_usage
            exit 1
        fi
        ;;
    v)
        CREATE_VOLUME_DIRECTORIES=1
        ;;
    *)
        print_usage
        exit 1
        ;;
    esac
done

SCRIPT_ROOT=https://raw.githubusercontent.com/software-pek-com/scripts/master

#####################################################################
# Functions

function mount_snapshot {
    if ! [ -z ${SNAPSHOT_ID} ]; then
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
    if ! [ -z ${CREATE_VOLUME_DIRECTORIES+x} ]; then
        curl ${SCRIPT_ROOT}/docker/create-volume-directories.sh > create-volume-directories.sh

        chmod 755 create-volume-directories.sh
        ./create-volume-directories.sh -d ${DOMAIN_NAME} -p /mnt/${STACK_NAME}
    fi
}

function create_bootstrap_log {
    echo "DomainName: ${DOMAIN_NAME}" >> boostrap.log
    echo "StackName: ${STACK_NAME}" >> boostrap.log
    echo "Snapshot: ${SNAPSHOT_ID}" >> boostrap.log
    echo "ScriptRoot: ${SCRIPT_ROOT}" >> boostrap.log
}

#####################################################################
# Body

create_bootstrap_log
exit 0;

# mount_snapshot
# update_and_install
# create_volume_directories

# exit 0;