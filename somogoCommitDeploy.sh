#!/bin/bash

. ~/.rvm/scripts/rvm

if [[ "$1" == *force* ]] ; then
  FORCE_COMMIT=true
  shift
fi

ENVIRONMENT="${1:-dev}"
myruby=$(cat .ruby-version)

echo $myruby

if [[ "$myruby" == 3.* ]] ; then
   myruby=3.1.2
else
  myruby=2.6.2
fi

BRANCH=${2:-RUBY-${myruby}}

echo Branch $BRANCH for ruby ${myruby}

pushd ${HOME}/repos/somogo  || exit 1

git checkout ${BRANCH}
git pull 
COMMIT=$(git rev-parse HEAD)

popd

[[ -n "$COMMIT" ]] || exit 1

TAG=$(git tag --points-at $(git rev-parse HEAD) | grep "^${ENVIRONMENT}-" | sort -n | tail -1)
if [[ "$TAG" == ${ENVIRONMENT}-202-*-*-* ]] && [[ "$TAG" != ${ENVIRONMENT}-$(date +%F)* ]] ; then
  echo Blanking tag because previous tag date is not today
  TAG=
fi
if [[ ! -n "$TAG" ]] ; then
  echo looking for any matching tags
  TAG=$(git tag  | grep "^${ENVIRONMENT}-" | grep -- "-$(date +%F)-" | sort -n | tail -1)
fi
if [[ -n "$TAG" ]] ; then
  NUMBER="${TAG##*-}"
  let NUMBER++ && NEWTAG="${TAG%-*}-${NUMBER}" || NEWTAG="${TAG}-1"
else
  NEWTAG=${ENVIRONMENT}-$(date +%F)-1
fi

[[ -n "$BRANCH" ]] && [[ -n "$COMMIT" ]] || exit 1

sed -i "" "s;.*git: .#{mogo_repo}/somogo.git.*;gem 'somogo', git: \"#{mogo_repo}/somogo.git\", branch: '${BRANCH}';g" Gemfile

rvm use $myruby

bundle lock --update somogo

if ! git commit -a -m "somogo version bump to ${BRANCH} COMMIT: $COMMIT" || ! git push ; then
   [[ "$FORCE_COMMIT" != "true" ]] && exit 0
fi

git tag $NEWTAG && git push origin $NEWTAG
