#!/bin/bash

# Site scanner using Mozilla Observatory tools
# Version: 0.0.1
# Author: Joshua I. James
# Date: 2020-03-08
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

TMP=$(mktemp)

DIR="out/$(basename $1 .txt)"
echo "Directory set to $DIR"
install -d "$DIR"

SITES=$1
if [ ! -f "$SITES" ]; then
    echo "Please enter a valid site list (one per line)."
fi

if [ "$2" == "" ]; then
  echo "Time,Site,OBS Score,OBS Grade,TLS Score,TLS Grade"
else
  echo "Time,Site,OBS Score,OBS Grade,TLS Score,TLS Grade,External Links" | tee -a "$2"
fi

# Functions

function getLinks {
    S=$(echo ${2//http:\/\/} | tr -d /)
    echo "" > $1 # clear the file
    xidel $2 -s --user-agent="Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.95 Safari/537.36" --extract "//link/@href" --extract "//script/@src" --extract "//iframe/@src" | sort | uniq | grep "//" | grep -v ${S} > $1
    #curl -L $S | tr '"' '\n' | tr "'" '\n' | grep -v "<a href" | grep -e '^https://' -e '^http://' -e'^//' | sort | uniq | grep -v ${S} > $1
    if [ $(cat "$1" | wc -l) -eq 0 ]; then
      EXTL="0"
    else
      cat "$1" | tee "$DIR/External-${S}.txt" >> "$DIR/External-All.txt"
      EXTL=$(cat "$DIR/External-${S}.txt" | wc -l)
    fi
}

# Main
while read SITE; do
  if [[ "$SITE" == *"#"* ]]; then
    continue
  fi
  >&2 echo "Running $SITE"
  DATE=$(date --iso-8601=minutes)
  OBS=$(httpobs-cli "$SITE" 2>/dev/null | grep Score: | awk '{print $3 "," $2}')
  TLS=$(tlsobs "$SITE" 2>/dev/null | grep Grade: | awk '{print $3 "," $4}')
  if [ "$TLS" == "" ]; then
    TLS="F, (0/100)"
  fi
  getLinks $TMP $SITE
  if [ "$2" == "" ]; then
     echo "$DATE,$SITE,$OBS,$TLS,$EXTL"
  else
     echo "$DATE,$SITE,$OBS,$TLS,$EXTL" | tee -a "$2"
  fi
done < "$SITES"

rm "$TMP"
