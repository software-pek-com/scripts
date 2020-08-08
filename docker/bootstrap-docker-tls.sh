#!/bin/bash

while getopts "s:" OPTION; do
    case ${OPTION} in
    s)
        STACK_NAME=${OPTARG}
        if [ -z ${STACK_NAME} ]; then
            echo "Stack name is required, use -s xyz"
            exit 1
        fi
        ;;
    *)
        echo "Incorrect options provided"
        exit 1
        ;;
    esac
done

if [ -z "${STACK_NAME}" ]; then
    echo "Stack name is required, use -s xyz"
    exit 1
fi

# Simplest way.
PUBLIC_IP=$(curl http://checkip.amazonaws.com/)
# Assumes EC2 Instance hostname e.g. ip-172-51-22-174.
PRIVATE_IP=$(hostname | cut -d- -f2- | sed 's/-/./g')
SCRIPT_ROOT=https://raw.githubusercontent.com/software-pek-com/scripts/master

# We need a directory where we can work freely.
cd /tmp

# Grab scripts
curl ${SCRIPT_ROOT}/ssl/generate-certificates.sh > generate-certificates.sh
curl ${SCRIPT_ROOT}/docker/configure-docker-tls.sh > configure-docker-tls.sh
chmod 755 generate-certificates.sh configure-docker-tls.sh

# Generate SSL certificates.
./generate-certificates.sh -s ${STACK_NAME} -p ${PRIVATE_IP} -u ${PUBLIC_IP}
# Configure docker with TLS.
./configure-docker-tls.sh

# Cleanup
rm -f ./generate-certificates.sh ./configure-docker-tls.sh

exit 0;
