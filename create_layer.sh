#!/bin/bash -e

LAYER_NAME="${1}"
RUNTIME_AND_VERSION="${2}"

CURRENT_FOLDER="$(pwd)"
RUNTIME="${RUNTIME_AND_VERSION%%":"*}"
VERSION="${RUNTIME_AND_VERSION#*":"}"
ZIP_ARTIFACT="${LAYER_NAME}-${RUNTIME_AND_VERSION//:/_}.zip"

function cleanWorkspace() {
    echo -e "Cleaning workspace: ${RUNTIME}/${LAYER_NAME}/${RUNTIME}"

    if [ -d "${RUNTIME}/${LAYER_NAME}/${RUNTIME}" ]; then
        rm -rf "${RUNTIME}/${LAYER_NAME}/${RUNTIME}"
    fi

    mkdir "${RUNTIME}/${LAYER_NAME}/${RUNTIME}"
}

function compress() {
    echo -e "Compressing layer"
    cd "${RUNTIME}/${LAYER_NAME}"
    zip -r ${ZIP_ARTIFACT} . -x ".git/*"
    cd "${CURRENT_FOLDER}"
}

function publish() {
    echo -e "Publishing layer to AWS"
    aws lambda publish-layer-version --layer-name ${LAYER_NAME} --zip-file fileb://${RUNTIME}/${LAYER_NAME}/${ZIP_ARTIFACT} --compatible-runtimes ${RUNTIME}${VERSION}
}

function run_container() {
    local DOCKER_RUNTIME="${1}"
    echo -e "Creating layer in Docker"
    docker run --rm -v $(pwd)/${RUNTIME}/${LAYER_NAME}:/var/task:z ${DOCKER_RUNTIME}:${VERSION} /bin/bash -c "${COMMAND}"
}

function usage() {
    echo -e "Usage: ${0} <LAYER_NAME> <RUNTIME_AND_VERSION>"
    echo -e ""
    echo -e "Options:"
    echo -e "    LAYER_NAME <python:3.9>"
    exit 1
}

echo -e "Creating a new layer for ${LAYER_NAME} using ${RUNTIME_AND_VERSION}"
echo -e ""

case ${RUNTIME} in
    nodejs)
        COMMAND="cd /var/task && npm install"
        cleanWorkspace
        run_container node
        compress
        cleanWorkspace
        ;;

    python)
        COMMAND="cd /var/task && python -m pip --isolated install -t ${RUNTIME} -r requirements.txt"
        cleanWorkspace
        run_container ${RUNTIME}
        compress
        cleanWorkspace
        ;;

    *)
        usage
        ;;
esac
