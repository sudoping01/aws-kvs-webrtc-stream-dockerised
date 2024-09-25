#!/bin/bash


set -e


log_error() {
    echo "ERROR: $1" >&2
}


log_info() {
    echo "INFO: $1"
}

check_file() {
    if [ ! -f "$1" ]; then
        log_error "File not found: $1"
        exit 1
    fi
}


if [ -z "$THING_CERT_DEST_PATH" ]; then
    log_error "THING_CERT_DEST_PATH is not set"
    exit 1
fi


CONFIG_FILE="${THING_CERT_DEST_PATH}/config.yaml"
check_file "$CONFIG_FILE"


read_config() {
    local value
    value=$(yq "$1" "$CONFIG_FILE")
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        log_error "Failed to read $1 from config.yaml"
        exit 1
    fi
    echo "$value"
}


export AWS_IOT_CORE_CERT="${THING_CERT_DEST_PATH}/$(read_config .certFile)"
export AWS_IOT_CORE_PRIVATE_KEY="${THING_CERT_DEST_PATH}/$(read_config .privateKeyFile)"
export AWS_IOT_CORE_CREDENTIAL_ENDPOINT=$(read_config .credentialEndpoint)
export AWS_IOT_CORE_THING_NAME=$(read_config .thingName)
export AWS_IOT_CORE_ROLE_ALIAS=$(read_config .roleAlias)
export AWS_KVS_CACERT_PATH="${THING_CERT_DEST_PATH}/$(read_config .rootCAFile)"


check_file "$AWS_IOT_CORE_CERT"
check_file "$AWS_IOT_CORE_PRIVATE_KEY"
check_file "$AWS_KVS_CACERT_PATH"


if [ -z "$CHANNEL_NAME" ]; then
    log_error "CHANNEL_NAME is not set"
    exit 1
fi

export KVS_CHANNEL_NAME=$CHANNEL_NAME


if [ -z "$PIPELINE" ]; then
    log_error "PIPELINE is not set"
    exit 1
fi

export PIPELINE=$PIPELINE


log_info "Configuration loaded successfully"
log_info "Channel Name: $KVS_CHANNEL_NAME"
log_info "Thing Name: $AWS_IOT_CORE_THING_NAME"


if [ -f "./iot_stream" ]; then
    log_info "Starting iot_stream..."
    ./iot_stream "$KVS_CHANNEL_NAME"
else
    log_error "iot_stream executable not found"
    exit 1
fi