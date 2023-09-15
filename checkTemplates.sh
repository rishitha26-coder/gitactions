#!/bin/bash

shopt -s extglob

export errors=0
export charts=0

  for chart in Charts/${1:-*} ; do
    [[ -d "$chart" ]] || continue
    [[ -f "${chart}/values.yaml" ]] || continue
    SERVICE=${chart##*/}
    for environment in ${chart}/${2:-*} ; do
      ENVIRONMENT=${environment##*/}
      [[ ! -d ${environment} ]] && continue
      [[ "$ENVIRONMENT" == "templates" ]] && continue
      [[ -f "${chart}/${ENVIRONMENT}/values.yaml" ]] || continue
      echo -n "Checking $SERVICE in $ENVIRONMENT ... "
      if [[ -s "Values/environments/values-${ENVIRONMENT}.yaml" ]] ; then
        HELMCMD="helm template $SERVICE $environment -f $chart/values.yaml -f Values/environments/values-${ENVIRONMENT}.yaml -f Values/${SERVICE}/values-${ENVIRONMENT}.yaml"
      else
        HELMCMD="helm template $SERVICE $environment -f $chart/values.yaml -f Values/${SERVICE}/values-${ENVIRONMENT}.yaml"
      fi
      if ! $HELMCMD > /dev/null 2>&1 ; then
        if [[ $ENVIRONMENT == @(training|demo) ]] ; then
           echo "${ENVIRONMENT} disabled, ignoring errors" >&2
        else
          let errors++
          echo -e "Errors found running:\n  $HELMCMD"
          $HELMCMD --debug
        fi
      else
        echo "OK."
        [[ "$DEBUG" == "true" ]] && $HELMCMD --debug
        if [[ "$VAULT_CHECK" == "true" ]] ; then
          export DIR=/tmp/https___github.com_mogofinancial_soa-helm-charts/Charts/${SERVICE}/${ENVIRONMENT}
          cat << EOF | kubectl --context=vault-nonprod -n mogo-argocd exec -it deployment/argo-cd-argocd-repo-server -- bash -sx -
              cd $DIR
              export TEMPFILE=$(mktemp /tmp/checkTemplates.sh.XXXXXX.yaml)
              $HELMCMD > \$TEMPFILE
              helm template --namespace $(yq e '.app.Namespace' ../values.yaml)-${ENVIRONMENT} -f ${DIR}/../values.yaml -f $DIR/values.yaml -f $DIR/../../../Values/environments/values-${ENVIRONMENT}.yaml -f $DIR/../../../Values/$($(yq e '.app.name' ../values.yaml)/values-${ENVIRONMENT}.yaml test . > \$TEMPFILE
              argocd-vault-plugin generate \$TEMPFILE
              rm -f $TEMPFILE
EOF
        fi
      fi
    done
    let charts++
  done

echo "$errors errors found in $charts charts!"

exit $errors
