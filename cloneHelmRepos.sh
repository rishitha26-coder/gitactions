#!/bin/bash 

exitscript () {
  echo Error cloning $SERVICE from $URL with path $SUBPATH and revision $VERSION >&2
  result="$1"
  shift
  [[ -n "$2" ]] && echo "$@" >&2
  exit $1
  }

cloneRepo () {

  shopt -s extglob

  SERVICE="$1"

  URL="$2"

  SUBPATH="${3:+${3%/}/}"

  VERSION="${4}"

  [[ -d Templates ]] || exitscript 1
  mkdir -p Templates/${SERVICE}
  pushd Templates/${SERVICE} || exitscript 1

  git init . || exitscript 1

  git config core.sparseCheckout true

  shift ; shift ; shift ; shift
  FILELIST=()
 
  if [[ -n "$1" ]] ; then
    FILELIST=($@)
  else
    FILELIST=(templates Chart.yaml values.yaml)
  fi

  echo > .git/info/sparse-checkout

  git remote add -f origin "${URL}"


  for file in ${FILELIST[@]} ; do
    [[ -f "$SUBPATH$file" ]] && rm -f ${SUBPATH}${file}
    [[ -d "$SUBPATH$file" ]] && rm -fr ${SUBPATH}${file}
    echo "$SUBPATH$file" >> .git/info/sparse-checkout
  done

  git pull origin $VERSION || exitscript 1

  if [[ -n "$SUBPATH" ]] ; then
    for file in ${FILELIST[@]} ; do
      [[ -L $file ]] || [[ ! -s $file ]] || continue
      ln -sfn ${SUBPATH}${file} ./ || exitscript 1
    done
  fi

  rm -fr .git
  
  git add .

  helm dependency build ./ || exitscript 1

  popd
  scripts/checkTemplateDefaults.sh $SERVICE || echo Clone of $SERVICE done, but template defaults may not be valid. Run DEBUG=true scripts/checkTemplateDefaults.sh $SERVICE to check tempalte contents

  }

if [[ "$0" != "scripts/cloneHelmRepos.sh" ]] ; then
  echo "Must be run as scripts/cloneHelmRepos.sh from the root of the soa-helm-charts repository!"
fi
clone-datadog () {
  cloneRepo datadog https://github.com/DataDog/helm-charts charts/datadog datadog-3.25.3 || exit 1
  }
clone-external-snapshotter () {
  cloneRepo external-snapshotter https://github.com/kubernetes-csi/external-snapshotter "" master client/config deploy/kubernetes/snapshot-controller || exit 1
  }
clone-rabbitmq () {
  cloneRepo rabbitmq https://github.com/bitnami/charts bitnami/rabbitmq 39b9204930a69eed8ca294429bcf47a76fa8816a || exit 1
  }
clone-redis () {
  cloneRepo redis https://github.com/bitnami/charts.git bitnami/redis e790bdd55bfe6b6d4c1647a2bd3fda7e40b0ff8c || exit 1
  }
clone-actions-runner-controller () {
  cloneRepo actions-runner-controller https://github.com/actions/actions-runner-controller charts/actions-runner-controller actions-runner-controller-0.23.3 || exit 1
  }
clone-haproxy () {
  cloneRepo haproxy https://github.com/haproxytech/helm-charts haproxy kubernetes-ingress-1.32.3 || exit 1
  }

$1
