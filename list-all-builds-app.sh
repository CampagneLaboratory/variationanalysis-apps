#!/usr/bin/env bash
if [ ! "$#" -eq 1 ]; then
    echo "Usage list-all-builds-app.sh APP_NAME"
    exit 1
fi
dx find apps --name $1 --all 
