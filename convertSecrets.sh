#!/bin/bash

usage () {
  echo "## This script is to be executed in the root of a repository to convert it's vault secrets from jfrog pipelines style to the new unified pipeline style."
  echo "## Note: you must be logged into vault on the cli to use this, and you need to have yq and jq installed on the cli as well!"
  echo 
  echo "Usage: ${0} <ENV> [<ENV2> .... ]"
  exit 1
  }

myrepo=$(git config --get remote.origin.url | sed -e 's;.*/\(.*\).git;\1;g' -e 's/_/-/g')

if [[ ! -n "$myrepo" ]] || [[ "$myrepo" == "soa-helm-charts" ]] ; then
  usage
fi

for env in "$@" ; do

  export secretpath=$(yq e '.SecretPath' helm/environments/${env}.yaml)
  [[ "$secretpath" == "null" ]] && secretpath=$(yq e '.SecretPath' helm/environments/default.yaml)
  [[ "$secretpath" == "null" ]] && secretpath=secrets/k8s/soa/kv

  export namespace=$(yq -e '.Namespace' helm/environments/${env}.yaml)
  [[ "$namespace" == "null" ]] && namespace=mogo-${env}

  if [[ "$env" == "prod" ]] ; then
     export VAULT_ADDR=https://vault.security.mogok8s.net
  else
     export VAULT_ADDR=https://vault-nonprod.security.mogok8s.net
  fi

  secret=$(vault kv get -format=json ${secretpath}/${namespace}/${myrepo} | jq .data.data)

  if [[ ! -n "$secret" ]] || [[ "$secret" == "null" ]] ; then
     usage
  fi
  result=0
  if [[ "$(echo $secret | jq -r .json)" == "null" ]] ; then
    echo "Converting secret to new format!"
    echo $secret | jq '{"json": .}' | vault kv put -format=json ${secretpath}/$namespace/$myrepo -
    result="$?"
  else
    echo "Secret appears to be in the new format already! Convert ${VAULT_ADDR}/ui/$secretpath/${namespace}/${myrepo} manually if it's not already converted."
  fi
  if [[ "$result" != "0" ]] ; then
    echo "Failed to update secret! Aborting."
    exit 1
  fi
  yq -i e '.secrets.enabled = "true"' helm/environments/${env}.yaml
  if [[ "$env" == "prod" ]] ; then
    yq -i e '.secrets.enabled = "true"' helm/environments/default.yaml
  fi
done

git diff && echo "Commit change to git to allow automatic secret creation for environments $@"
