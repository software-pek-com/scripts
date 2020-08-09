#!/bin/bash

local me=`basename "$0"`

# Script interface (required options):
function print_usage {
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

# echo "DomainName: ${DOMAIN_NAME}"
# echo "StackName: ${STACK_NAME}"
# echo "Snapshot: ${SNAPSHOT_ID}"

mkdir /mnt/${SNAPSHOT_ID}
ln -s /mnt/${SNAPSHOT_ID} /mnt/${STACK_NAME}
mkfs.xfs /dev/xvdf
echo "/dev/xvdf	/mnt/${STACK_NAME}	auto	defaults,nofail	0	2" >> /etc/fstab
mount -a

apt-get -y update
apt-get -y install \
    apt-transport-https \
    ca-certificates \
    # curl should be there!
    curl \
    gnupg-agent \
    software-properties-common \
    docker-compose
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y install docker-ce docker-ce-cli containerd.io
usermod -aG docker ubuntu
curl https://raw.githubusercontent.com/software-pek-com/scripts/master/docker/bootstrap-docker-tls.sh > /tmp/bootstrap-docker-tls.sh
chmod 755 /tmp/bootstrap-docker-tls.sh
/tmp/bootstrap-docker-tls.sh -d ${DOMAIN_NAME} -n ${STACK_NAME}
rm -f /tmp/bootstrap-docker-tls.sh

exit 0;