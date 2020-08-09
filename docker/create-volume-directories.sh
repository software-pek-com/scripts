#!/bin/bash

while getopts "d:p:" OPTION; do
    case ${OPTION} in
    d)
        DOMAIN_NAME=${OPTARG}
        if [ -z ${DOMAIN_NAME} ]; then
            echo "Domain name is required, use -d xyz.com"
            exit 1
        fi
        ;;
    p)
        DEPLOY_PATH=${OPTARG}
        if [ -z ${DEPLOY_PATH} ]; then
            echo "Path is required, use -p xyz"
            exit 1
        fi
        ;;
    *)
        echo "Incorrect options provided"
        exit 1
        ;;
    esac
done

if [ -z "${DOMAIN_NAME}" ]; then
    echo "Domain name is required, use -d xyz.com"
    exit 1
fi

if [ -z "${DEPLOY_PATH}" ]; then
    echo "Path is required, use -p xyz"
    exit 1
fi

if [ ! -d "${DEPLOY_PATH}" ]; then
    echo "Path ${DEPLOY_PATH} invalid (does not exists)." 
    exit 1
fi

mkdir -p ${DEPLOY_PATH}
mkdir -p ${DEPLOY_PATH}/nginx-proxy
mkdir -p ${DEPLOY_PATH}/nginx-proxy/certs
mkdir -p ${DEPLOY_PATH}/nginx-proxy/conf.d
mkdir -p ${DEPLOY_PATH}/nginx-proxy/html
mkdir -p ${DEPLOY_PATH}/nginx-proxy/vhost.d

mkdir -p ${DEPLOY_PATH}/${DOMAIN_NAME}
mkdir -p ${DEPLOY_PATH}/${DOMAIN_NAME}/db
mkdir -p ${DEPLOY_PATH}/${DOMAIN_NAME}/www

curl -o ${DEPLOY_PATH}/nginx.tmpl https://raw.githubusercontent.com/jwilder/docker-gen/master/templates/nginx.tmpl

chown -R root ${DEPLOY_PATH}
chgrp -R root ${DEPLOY_PATH}
chown www-data ${DEPLOY_PATH}/${DOMAIN_NAME}/www
chgrp www-data ${DEPLOY_PATH}/${DOMAIN_NAME}/www
