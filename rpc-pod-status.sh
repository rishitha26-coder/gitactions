#!/bin/bash

kubectl --context=soa-shared-legacy -n mogo-dev get pods -l "app in ($(echo $(cat ~/repos/soa-helm-charts/Charts/services.txt | grep -- -rpc | sed 's/$/,/g'))none)" "$@"
