#!/bin/bash

while getopts "s:p:u:" OPTION; do
    case ${OPTION} in
    s)
        STACK_NAME=${OPTARG}
        if [ -z ${STACK_NAME} ]; then
            echo "Stack name is required, use -s xyz"
            exit 1
        fi
        ;;
    p)
        PRIVATE_IP=${OPTARG}
        if [ -z "${PRIVATE_IP}" ]; then
            echo "Private IP address is required, use -p xyz"
            exit 1
        fi
        ;;
    u)
        PUBLIC_IP=${OPTARG}
        if [ -z "${PUBLIC_IP}" ]; then
            echo "Public IP address is required, use -u xyz"
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
if [ -z "${PRIVATE_IP}" ]; then
    echo "Private IP address is required, use -p xyz"
    exit 1
fi
if [ -z "${PUBLIC_IP}" ]; then
    echo "Public IP address is required, use -u xyz"
    exit 1
fi

GENPKEY_OPTS="-algorithm RSA -pkeyopt rsa_keygen_bits:2048"
TEN_YEARS_IN_DAYS=3650

TS=$(date +%Y%m%d_%H%M%S)
#OUT_DIR=docker-tls-${TS}
OUT_DIR=${STACK_NAME}-${TS}
DOCKER_DIR=/etc/docker/ssl

mkdir ${OUT_DIR}
chmod 0755 ${OUT_DIR}/
cd ${OUT_DIR}

###########################################################
# CA key
openssl genpkey ${GENPKEY_OPTS} -out ca-key.pem

# CA certificate
openssl req -new -x509 -days ${TEN_YEARS_IN_DAYS} -subj "/CN=${STACK_NAME}-ca"  -key ca-key.pem -sha256 -out ca.pem

###########################################################
# Server key
openssl genpkey ${GENPKEY_OPTS} -out server-key.pem

# Server CSR
openssl req -new -subj "/CN=${STACK_NAME}-server" -key server-key.pem -out server.csr

# Alts IPs
echo "subjectAltName = IP:${PUBLIC_IP},IP:${PRIVATE_IP},IP:127.0.0.1" \
    > server-extfile.cnf

# Server certificate
openssl x509 -req -days ${TEN_YEARS_IN_DAYS} \
    -extfile server-extfile.cnf -in server.csr \
    -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
    -out server-cert.pem

###########################################################
# Client key
openssl genpkey ${GENPKEY_OPTS} -out client-key.pem

# Client CSR
openssl req -new -subj "/CN=${STACK_NAME}-client" -key client-key.pem -out client.csr

# clientAuth
echo "extendedKeyUsage = clientAuth" > client-extfile.cnf
# Client certificate
openssl x509 -req -days ${TEN_YEARS_IN_DAYS} \
    -extfile client-extfile.cnf -in client.csr \
    -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
    -out client-cert.pem

# Securing
chmod -v 0444 *
chmod -v 0400 *-key.pem

cd ..

# Moving
sudo mkdir -p ${DOCKER_DIR}
sudo chown root:docker ${DOCKER_DIR}
sudo chmod 700 ${DOCKER_DIR}
sudo cp ${OUT_DIR}/{ca,server-*}.pem ${DOCKER_DIR}

exit 0;
