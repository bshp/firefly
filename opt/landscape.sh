#!/bin/bash

landscape-config --computer-title "${hostname^^}" --account-name standalone  -p ${LANDSCAPE_TOKEN} --url ${LANDSCAPE_URL}/message-system --ping-url ${LANDSCAPE_URL}/ping
echo "Landscape installed and is reporting to " ${LANDSCAPE_URL}
