#!/bin/bash

INSTALL_PATH="/usr/local/carbon_client"

if [ -e ${INSTALL_PATH} ]
then
    echo "error, install path ${INSTALL_PATH} does already exist"
    exit 1
fi

echo "preparing directory ${INSTALL_PATH}"
mkdir ${INSTALL_PATH}

cp ./carbon_server.conf ${INSTALL_PATH}
cp ./generic_carbon_client.pl ${INSTALL_PATH}

mkdir -p ${INSTALL_PATH}/plugins/execution_states

chmod 777 ${INSTALL_PATH}/plugins/execution_states

echo "done!"

echo "TODO:"

echo "- copy this to the crontab of an unprivileged user:"
echo "     * * * * * ${INSTALL_PATH}/generic_carbon_client.pl"
echo "- make sure the user has write permissions on ${INSTALL_PATH}/plugins/execution_states"
