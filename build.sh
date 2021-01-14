#!/usr/bin/env bash
# arg1: name of destination dockerhub
# arg2: dockerhub username
# arg3: dockerhub password

set -x -e

buildnumber=${4-$(date -u +"%y%m%d%H%M")}

# docker login -u "$2" -p "$3"

# build base images
docker build -q -t "$1"/apache24:php73-custom_"$buildnumber" .

# run container
# docker run -p 8080:80 --name apache24_"$buildnumber" "$1"/apache24:php73-custom_"$buildnumber"

# docker push to registory
# docker push "$1"/php:7.3-apache-custom_"$buildnumber"

# docker logout
