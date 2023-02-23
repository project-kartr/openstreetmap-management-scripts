# Skript to prerender Germany with the perl skript.

#!/bin/bash
if [[ -z $1 ]] || [[ -z $2 ]] || [[  "$1" =~ ^-h$|^--help  ]]; then
  echo "usage: ./preRenderBhvWithPerl.sh <from Zoomlevel> <to Zoomlevel>"
else
  echo "Bremerhaven will be prerenderd from zoomlevel $1 to zoomlevel $2"
fi
 
./render_list_geo.pl -n 15 -m s2o -z $1 -Z $2 -x 5.38 -X 15.3 -y 47.2 -Y 56.34 -l 99999

