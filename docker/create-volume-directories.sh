#!/bin/bash

me=`basename "$0"`

# Script interface (required options):
function print_usage {
    echo "usage: $me [-d domainname] [-p deploypath]"
    echo "  -d domainname  e.g. xyz.com"
    echo "  -p deploypath  e.g. /mnt/xyz"
}

# We need 2 options with values so there must be 4 script arguments
if [ $# -ne 4 ]; then
    print_usage
    exit 1
fi

while getopts "d:p:" OPTION; do
    case ${OPTION} in
    d)
        DOMAIN_NAME=${OPTARG}
        if [ -z ${DOMAIN_NAME} ]; then
            print_usage
            exit 1
        fi
        ;;
    p)
        DEPLOY_PATH=${OPTARG}
        if [ -z ${DEPLOY_PATH} ]; then
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

if [ ! -d "${DEPLOY_PATH}" ]; then
    echo "$me: path does not exist '${DEPLOY_PATH}'." 
    exit 1
fi

function create_nginx_directories {
    mkdir -p ${DEPLOY_PATH}/nginx-proxy
    mkdir -p ${DEPLOY_PATH}/nginx-proxy/certs
    mkdir -p ${DEPLOY_PATH}/nginx-proxy/conf.d
    mkdir -p ${DEPLOY_PATH}/nginx-proxy/html
    mkdir -p ${DEPLOY_PATH}/nginx-proxy/vhost.d
}

function create_db_directories {
    mkdir -p ${DEPLOY_PATH}/${DOMAIN_NAME}/db
}

function create_www_directories {
    mkdir -p ${DEPLOY_PATH}/${DOMAIN_NAME}/www
    
    chown www-data ${DEPLOY_PATH}/${DOMAIN_NAME}/www
    chgrp www-data ${DEPLOY_PATH}/${DOMAIN_NAME}/www
}

mkdir -p ${DEPLOY_PATH}
mkdir -p ${DEPLOY_PATH}/${DOMAIN_NAME}

create_nginx_directories
create_db_directories
create_www_directories

chmod -R 755 ${DEPLOY_PATH}