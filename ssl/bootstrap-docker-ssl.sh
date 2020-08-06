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

PUBLIC_IP=$(curl http://checkip.amazonaws.com/)
PRIVATE_IP=$(hostname | cut -d- -f2- | sed 's/-/./g')
SCRIPT_ROOT=https://raw.githubusercontent.com/software-pek-com/scripts/master/ssl

# Assumes we are in a directory where we can work freely e.g. /tmp.
cd /tmp

curl ${SCRIPT_ROOT}/generate-certificates.sh >> generate-certificates.sh
curl ${SCRIPT_ROOT}/setup-docker-certificates.sh >> setup-docker-certificates.sh
chmod 755 generate-certificates.sh setup-docker-certificates.sh

./generate-certificates.sh -s ${STACK_NAME} -p ${PRIVATE_IP} -u ${PUBLIC_IP}
./setup-docker-certificates.sh

exit 0;
