#!/bin/bash

shopt -s extglob

helm template --debug Templates/${1}/ -f Templates/local-values.yaml -f Templates/${1}/values.yaml -f Values/environments/values-${2:-dev}.yaml
