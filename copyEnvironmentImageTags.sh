#!/bin/bash

SOURCE_ENVIRONMENT=$1
TARGET_ENVIRONMENT=$2
SERVICES=$3

grep ' image_tag' Values/${SERVICES:-*}/values-${SOURCE_ENVIRONMENT}.yaml | grep -v -- '-rpc/' | \
  while read line ; do
    [[ -n "$line" ]] || continue
    if [[ -n "$SERVICES" ]] ; then
      service=$SERVICES
      image=$(echo $line | cut -d " " -f 2-) 
    else
      service=$(echo $line | cut -d / -f 2)
      image=$(echo $line | cut -d " " -f 3-) 
    fi
    [[ -n "$service" ]] && [[ -n "$image" ]] || continue
    yq -i -e ".config.image_tag = ${image}" Values/${service}/values-${TARGET_ENVIRONMENT}.yaml
  done
