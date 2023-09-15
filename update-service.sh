#!/bin/bash 

ORG=mogofinancial
ACTION_REPO=soa-helm-charts

export TLS_VERSION=${TLS_VERSION:-1.3}

shopt -s extglob

REPO="$1"

if [[ ! -n "$REPO" ]] ; then
	echo "Usage ${0} <repository> <environment> [<BRANCH>] [<TAG>] [<IS_RELEASE>]"
	exit 1
fi

if [[ "$USER" == *.* ]] ; then
  DEFAULT_EMAIL="${USER}@mogo.ca"
else
  DEFAULT_EMAIL=ist-devops@mogo.ca
fi

ENVIRONMENT="${2}"
TAG="${3}"
EMAIL="${4:-${DEFAULT_EMAIL}}"
BRANCH="${5}"
IS_RELEASE="${6:-false}"
DEBUG="${7:-false}"
HELM_PREFIX="${8:-false}"
COMMITID="$(git rev-parse HEAD)"

[[ -n "$GITHUB_TOKEN" ]] || . ~/.bashrc

if [[ ! -n "$GITHUB_TOKEN" ]] ; then
	echo 'No GITHUB_TOKEN set! This script requires the GITHUB_TOKEN environment variable to contain a token that can push to soa-helm-charts!'
	exit 1
fi

curl --tlsv${TLS_VERSION} -d "{\"event_type\": \"update-service-v1\", \"client_payload\": {\"environment\": \"${ENVIRONMENT}\", \"helm_prefix\": \"${HELM_PREFIX}\", \"email\": \"${EMAIL}\", \"repo\": \"${REPO}\", \"branch\": \"${BRANCH}\", \"is_release\": \"${IS_RELEASE}\", \"tag\": \"$TAG\", \"debug\": \"${DEBUG:-false}\", \"commitid\": \"$COMMITID\"}}" -H "Content-Type: application/json" -H "Authorization: token ${GITHUB_TOKEN//$'\n'/}" -H "Accept: application/vnd.github.everest-preview+json" "https://api.github.com/repos/${ORG}/${ACTION_REPO}/dispatches"
