#!/bin/bash

args=
if [[ "$1" == *doit ]] ; then
  args="-i ''"
  shift
fi

filelist=$(grep -r --files-with-matches '= Redis.new' "$@" | grep -v 'Redis.new(no_namespace: true)')

[[ ! -n "$args" ]] && echo "Lines what would be changd:"
for file in $filelist ; do
  echo "$file:"
  [[ -n "$args" ]] || echo "--- $file"
  grep '= Redis.new' "$file"
  [[ -n "$args" ]] ||  echo "+++ $file"
  sed $args  -e 's/ Redis.new$/ Somogo::Redis.new(no_namespace: true)/g' \
             -e 's/ Redis.new\(.*(.*\))/ Somogo::Redis.new\1,no_namespace: true)/g' \
             -e "s/require 'redis'/require 'somogo'/g" \
         $file | grep 'Redis.new.*('
done
