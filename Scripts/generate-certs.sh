#!/bin/bash

# Function to create a private key
generate_key() {
    local key_path=$1
    openssl genrsa -out "${key_path}" 2048
}

# Function to create a Certificate Signing Request (CSR)
generate_csr() {
    local key_path=$1
    local csr_path=$2
    local subj=$3
    openssl req -new -key "${key_path}" -out "${csr_path}" -subj "${subj}"
}

# Function to sign a CSR
sign_csr() {
    local csr_path=$1
    local cert_path=$2
    local ca_cert=$3
    local ca_key=$4
    openssl x509 -req -in "${csr_path}" -CA "${ca_cert}" -CAkey "${ca_key}" -CAcreateserial -out "${cert_path}" -sha256
}

# Base working directory
BASE_DIR=~/SSL-IoT
CERTS=("Broker" "Subscriber" "Publisher")

# CA setup
CA_SUBJ="/C=US/ST=PA/L=Pittsburgh/CN=LMAuhtority"
CA_KEY="${BASE_DIR}/Broker/config/certs/ca.key"
CA_CERT="${BASE_DIR}/Broker/config/certs/ca.crt"

# create the CA certificate
generate_key "${CA_KEY}"
openssl req -x509 -new -nodes -key "${CA_KEY}" -sha256 -out "${CA_CERT}" -subj "${CA_SUBJ}"

if [[ ! -f "${CA_CERT}" ]]; then
    echo "CA certificate not found. Exiting."
    exit 1
fi

# Generate Certificates and keys for the Broker, Subscriber, and Publisher
for CERT in "${CERTS[@]}"; do

    if [[ "${CERT}" == "Broker" ]]; then
        DIR="${BASE_DIR}/Broker/config/certs"
    else
        DIR="${BASE_DIR}/${CERT}/certs"
    fi

    # set the filepaths for the keys and certificates
    CURR_KEY="${DIR}/${CERT,,}.key"
    CURR_CSR="${DIR}/${CERT,,}.csr"
    CERT_PATH="${DIR}/${CERT,,}.crt"

    # generate the keys and certificates
    generate_key "${CURR_KEY}"
    generate_csr "${CURR_KEY}" "${CURR_CSR}" "${CA_SUBJ}"
    sign_csr "${CURR_CSR}" "${CERT_PATH}" "${CA_CERT}" "${CA_KEY}"
done