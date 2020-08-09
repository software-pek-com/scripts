#!/bin/bash

#####################################################################
# Usage
function print_usage {    
    local me=`basename "$0"`
    echo "usage: $me [-d domainname] [-n stackname] [-s snapshotid]"
    echo "  -d domainname  e.g. xyz.com"
    echo "  -n stackname   e.g. xyz-com"
    echo "  -s snapshotid  e.g. snap-123"
}

# We need 3 options with values so there must be 6 script arguments
if [ $# -ne 6 ]; then
    print_usage
    exit 1
fi

while getopts "d:n:s:" OPTION; do
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
    *)
        print_usage
        exit 1
        ;;
    esac
done

SCRIPT_ROOT=https://raw.githubusercontent.com/software-pek-com/scripts/master

#####################################################################
# Functions

function bootstrap_docker_tls {
    curl https://raw.githubusercontent.com/software-pek-com/scripts/master/docker/bootstrap-docker-tls.sh > /tmp/bootstrap-docker-tls.sh
    chmod 755 /tmp/bootstrap-docker-tls.sh
    /tmp/bootstrap-docker-tls.sh -d ${DOMAIN_NAME} -n ${STACK_NAME}
    rm -f /tmp/c-docker-tls.sh
}

function create_volume_directories {
    curl ${SCRIPT_ROOT}/docker/create-volume-directories.sh > create-volume-directories.sh

    chmod 755 create-volume-directories.sh
    ./create-volume-directories.sh -d ${DOMAIN_NAME} -p /mnt/${STACK_NAME}
}

function create_bootsrap_log {
    echo "DomainName: ${DOMAIN_NAME}" >> boostrap.log
    echo "StackName: ${STACK_NAME}" >> boostrap.log
    echo "Snapshot: ${SNAPSHOT_ID}" >> boostrap.log
    echo "ScriptRoot: ${SCRIPT_ROOT}" >> boostrap.log
}

#####################################################################
# Body

create_bootsrap_log
# exit 0;

mkdir /mnt/${SNAPSHOT_ID}
ln -s /mnt/${SNAPSHOT_ID} /mnt/${STACK_NAME}
mkfs.xfs /dev/xvdf
echo "/dev/xvdf	/mnt/${STACK_NAME}	auto	defaults,nofail	0	2" >> /etc/fstab
mount -a

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

# Uncomment below if you want to configure docker for remote access using TLS.
# It works, but in the end remote docker admin is more trouble than it is worth.
# E.g. docker-compose takes any 'host' defined volumes from local not remote disk.
# bootstrap_docker_tls

create_volume_directories

exit 0;