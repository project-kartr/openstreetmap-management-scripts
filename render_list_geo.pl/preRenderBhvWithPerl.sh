# Skript to prerender Bremerhaven with the perl skript.

#!/bin/bash
if [[ -z $1 ]] || [[ -z $2 ]] || [[  "$1" =~ ^-h$|^--help  ]]; then
  echo "usage: ./preRenderBhvWithPerl.sh <from Zoomlevel> <to Zoomlevel>"
else
  echo "Bremerhaven will be prerenderd from zoomlevel $1 to zoomlevel $2"
fi
./render_list_geo.pl -n 15 -m s2o -z $1 -Z $2 -x 8.231 -X 9.237 -y 52.7 -Y 54 -l 99999

