#!/bin/bash

shopt -s extglob

cmd="$1"
shift
export ENV="$1"

shift

switchService () {
   SERVICE="$1"
   IMAGE_TAG="$2"
   TARGET_FILE=Values/${SERVICE}/values-${ENV}.yaml
   if [[ "$3" != *nobackup* ]] ; then
      cp ${TARGET_FILE} ${TARGET_FILE}.$(date +%F_%H-%M).backup || exit 1
   fi
   yq e -i '.config.'${service//-/_}'_image_tag = "'${IMAGE_TAG}'"' $TARGET_FILE || exit 1
   yq e -i '.config.image_tag = "'${IMAGE_TAG}'"'  $TARGET_FILE || exit 1
  }

makeBackups () {
   SERVICE="$1"
   TARGET_FILE=Values/${SERVICE}/values-${ENV}.yaml
   cp ${TARGET_FILE} ${TARGET_FILE}.$(date +%F_%H-%M).backup || exit 1
   
   }

revertBackups () {
   SERVICE="$1"
   TARGET_FILE=Values/${SERVICE}/values-${ENV}.yaml
   mv ${TARGET_FILE}.$(date +%F)_*.backup ${TARGET_FILE}
   }

prefetch () {

  for service in member-service card-service mortgage-service bank-service id-protect-service crypto-service crypto-exchange-service loan-service operations-service ; do
     switchService $service feature-prefetch $1
  done
  }

revertAll () {

  for service in member-service card-service mortgage-service bank-service id-protect-service crypto-service crypto-exchange-service loan-service operations-service http-service ; do
     revertBackups $service
  done
  }

oldhttpandmember () {

     switchService http-service release-20220628-02-hotfix-01 $1
     switchService member-service release-20220913-01 $1
  }

copyservicevalue () {
  SOURCEENV=$ENV
  DESTENV="$1"
  SERVICE="$2"
  shift ; shift
  SOURCE_FILE=Values/${SERVICE}/values-${SOURCEENV}.yaml
  TARGET_FILE=Values/${SERVICE}/values-${DESTENV}.yaml
  [[ -s "$SOURCE_FILE" ]] && [[ -s "$TARGET_FILE" ]] || exit 0
  for KEY in ${@} ; do
    SOURCE_VALUE="$(yq -e ".${KEY}" $SOURCE_FILE)"
    if [[ ! -n "$SOURCE_VALUE" ]] ; then
       echo $KEY is empty in $SOURCE_FILE, skipping
       return 0
    fi
    yq -e -i ".${KEY} = \"${SOURCE_VALUE}\"" $TARGET_FILE && echo Changed $KEY to $SOURCE_VALUE in $DESTENV
  done
  }

$cmd "$@"
