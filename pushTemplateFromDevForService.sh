#!/bin/bash
#env=qa ; for a in * ; do a=${a//_/-} ; rsync -av ~/repos/soa-helm-charts/Charts/$a/$env/ ~/repos/soa-helm-charts/Charts/$a/${env}.backup/ && rm -fr ~/repos/soa-helm-charts/Charts/$a/${env}/templates && rsync -av ~/repos/soa-helm-charts/Charts/${a}/dev/templates/ ~/repos/soa-helm-charts/Charts/${a}/${env}/templates/ ; done
#for a in * ; do a=${a//_/-} ; ~/repos/soa-helm-charts/scripts/cleanTemplateValues.sh ~/repos/soa-helm-charts/Charts/${a}/${env}/values.yaml ; done
#for a in * ; do a=${a//_/-} ; ln -sfn ../values.yaml  ~/repos/soa-helm-charts/Charts/${a}/${env}/argocd.yaml ; done

SERVICE=${1//_/-}
ENV=$2
REPO="${3:-${HOME}/repos/soa-helm-charts}"
CHARTSDIR="/Charts"

SOURCE=${REPO}/${CHARTSDIR}/${SERVICE}/dev
TARGET=${REPO}/${CHARTSDIR}/${SERVICE}/${ENV}
RPCTARGET=${REPO}/${CHARTSDIR}/${SERVICE}-rpc/${ENV}

if [[ ! -n "$SERVICE" ]] || [[ ! -n "$ENV" ]] || [[ "$ENV" == "dev" ]] || [[ ! -d ${TARGET} ]] ; then
  echo "Usage: ${0} <SERVICE> <TARGET ENVIRONMENT> [ repository directory ]. Uses dev env as source, so doesn't work for dev!"
  exit 1
fi

set -e

if [[ ! -d "${TARGET}.backup" ]] ; then
  echo Backing up to ${TARGET}.backup
  rsync -av ${TARGET}/ ${TARGET}.backup/
fi

rm -fr ${TARGET}/templates

${REPO}/scripts/cleanTemplateValues.sh ${TARGET}/values.yaml

rsync -av ${SOURCE}/templates ${TARGET}/

cd ${TARGET}

if [[ -s ../argocd.yaml ]] ; then
  ln -sfn ../argocd.yaml ./
fi

ln -sfn ../Chart.yaml ./

${REPO}/scripts/checkTemplates.sh ${SERVICE} ${ENV}

if [[ -d "$RPCTARGET" ]] ; then
  echo "Linking ${RPCTARGET} as well"
  rm -fr ${RPCTARGET}
  mkdir ${RPCTARGET}
  cd ${RPCTARGET}
  ln -sfn ../../${SERVICE}/${ENV}/templates ./
  ln -sfn ../../${SERVICE}/${ENV}/values.yaml ./
  ln -sfn ../argocd.yaml ../Chart.yaml ./
  ls -lad ${RPCTARGET}/*
fi

ls -lad ${TARGET}/*
