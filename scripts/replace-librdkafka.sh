#!/bin/bash

CONTAINER_HAS_RUN_BEFORE=""$CONF_FILES"/CONTAINER_HAS_RUN_BEFORE"
if [ ! -e $CONTAINER_HAS_RUN_BEFORE ]; then

    # Checking for required environment variable
    if [[ -z "${PROGRAM_HOME}" ]]; then
        echo -e "\e[1;31mERROR - Missing 'PROGRAM_HOME' environment variable \e[0m"
        exit 1
    fi

    rm -f ${PROGRAM_HOME}/runtimes/linux-x64/native/librdkafka.so

    mv /librdkafka/librdkafka*.so* ${PROGRAM_HOME}/runtimes/linux-x64/native/

    # Creating a file which in future runs will determine that the librdkafka dependency already has been moved
    touch $CONTAINER_HAS_RUN_BEFORE
fi
