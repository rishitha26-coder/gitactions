#!/bin/bash

for a in "$@" ; do
     echo "Cleaning $a"
     yq -i e '.config.*_stub = "" | 
         del(.config.shared_environment_environment,.*_service_max_replicas,.*_service_min_replicas,.config.*image_tag,.config.*replicas,.Environment,.config.shared_environment_url,.Namespace,.autoscaling,.config."*_stub") ' $a
     sed -i '' -e 's/config: {}//g' $a
done

