#!/bin/bash
# Henrik Cohrs, Jannes Elflein, Jannik Peters, Luca Heise
# 2022.11.22
# Script to setup an OSM Server with auto map updates and monitoring
# Derived from: 
# https://switch2osm.org/serving-tiles/manually-building-a-tile-server-debian-11/ <-- setup OSM server
# https://switch2osm.org/serving-tiles/updating-as-people-edit-osm2pgsql-replication/ <-- automatic map updates
# https://switch2osm.org/serving-tiles/monitoring-using-munin/ <-- monitoring

startTime=$(date +%s)
if [[ -z "$1" ]]; then
  echo "You did not specify a .pbf do you want to install"
  echo "<1> Germany"
  echo "<2> Bremen"
  echo "<3> Help"
  read decision
fi


case $decision in
  1)
    wget https://download.geofabrik.de/europe/germany-latest.osm.pbf
    pathOfPbf=$(realpath germany-latest.osm.pbf)
    ;;
  2)
    wget https://download.geofabrik.de/europe/germany/bremen-latest.osm.pbf
    pathOfPbf=$(realpath bremen-latest.osm.pbf)
    ;;
  3)
    help="1"
    ;;
esac


if [[ $help == "1" || "$1" =~ ^-h$|^--help$ ]]; then
	{
	echo "Usage $0 <osm file.osm.pbf>"
	} >&2
	exit
fi


if [[ -z $pathOfPbf ]]; then
  pathOfPbf=$(realpath $1)
fi


# Check if user is root
if [[ "$(id -u)" == 0 ]]; then
    echo "Please don't run as root" >&2
    exit
fi


# Check if there is enaugh avalable diskspace left
if [[  $(df "/" | grep "/" | tr -s ' '| cut -d ' ' -f 4) -lt 8000000  ]]; then
  {
  echo "not enaugh diskspace"
  } >&2
  exit
fi


# Update and upgrade the system
echo -e "\n---------------------------------------"
echo "|update and upgrade                   |"                 
echo "---------------------------------------"
sudo apt -y update

export DEBIAN_FRONTEND=noninteractive
sudo -E apt -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" upgrade -q -y --allow-downgrades --allow-remove-essential --allow-change-held-packages


# Install packages
echo -e "\n---------------------------------------"
echo "|installing packages                  |"
echo "---------------------------------------"
sudo apt -y install \
sudo \
screen \
locate \
libapache2-mod-tile \
vim \
renderd \
python3-pip \
git \
tar \
unzip \
wget \
bzip2 \
apache2 \
lua5.1 \
mapnik-utils \
python3-mapnik \
python3-psycopg2 \
python3-yaml \
gdal-bin \
npm \
fonts-noto-cjk \
fonts-noto-hinted \
fonts-noto-unhinted \
fonts-unifont \
fonts-hanazono \
postgresql \
postgis \
osm2pgsql \
cowsay

# Expand swap
sudo fallocate -l 64G /var/swapfile2
sudo chmod 600 /var/swapfile2
sudo mkswap /var/swapfile2
sudo swapon /var/swapfile2
sudo tee -a /etc/fstab <<EOF
/var/swapfile2 none swap sw 0 0
EOF

# Start postgres
echo -e "\n---------------------------------------"
echo "|stating postgresqp                   |"
echo "---------------------------------------"
sudo service postgresql start


# Create database user and database
echo -e "\n---------------------------------------"
echo "|create db things                     |"
echo "---------------------------------------"
sudo -u postgres bash -c "createuser _renderd; createdb -E UTF8 -O _renderd gis"


# Setup database for use with geofiles
echo -e "\n---------------------------------------"
echo "|setup database                       |"
echo "---------------------------------------"
sudo -u postgres bash -c "psql -d gis -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore; ALTER TABLE geometry_columns OWNER TO _renderd; ALTER TABLE spatial_ref_sys OWNER TO _renderd;'"


# Stylesheet configuration
echo -e "\n---------------------------------------"
echo "|Stypesheet configuration             |"
echo "---------------------------------------"
mkdir ~/src
cd ~/src

git clone https://github.com/gravitystorm/openstreetmap-carto
cd openstreetmap-carto
sudo npm install -g carto
carto project.mml > mapnik.xml


# Load data
echo -e "\n---------------------------------------"
echo "|loading data                         |"
echo "---------------------------------------"
mkdir ~/data
cd ~/data
sudo -u _renderd osm2pgsql -d gis --create --slim  -G --hstore --tag-transform-script ~/src/openstreetmap-carto/openstreetmap-carto.lua -C 14000 --number-processes 15 -S ~/src/openstreetmap-carto/openstreetmap-carto.style "$pathOfPbf"


# Create indexes
echo -e "\n---------------------------------------"
echo "|createing indexes                    |"
echo "---------------------------------------"
cd ~/src/openstreetmap-carto/
sudo -u _renderd psql -d gis -f indexes.sql


# Install missing Python packages
echo -e "\n----------------------------------------"
echo "|install missing Python packages       |"
echo "----------------------------------------"
sudo pip install requests
sudo pip install requests_file


# Download shapefiles
echo -e "\n--------------------------------------------------"
echo "|shapefile download                              |"
echo "--------------------------------------------------"
cd ~/src/openstreetmap-carto/
mkdir data
sudo chown _renderd data
sudo -u _renderd scripts/get-external-data.py


# Setup webserver
echo -e "\n--------------------------------------------"
echo "|setup Webserver                           |"
echo "--------------------------------------------"
sudo tee /etc/renderd.conf <<EOF
[renderd]
stats_file=/run/renderd/renderd.stats
socketname=/run/renderd/renderd.sock
num_threads=15
tile_dir=/var/cache/renderd/tiles

[mapnik]
plugins_dir=/usr/lib/mapnik/3.1/input
font_dir=/usr/share/fonts/truetype
font_dir_recurse=true

[s2o]
URI=/map/
TILEDIR=/var/lib/mod_tile
XML=/home/$USER/src/openstreetmap-carto/mapnik.xml
HOST=localhost
TILESIZE=512
MAXZOOM=20
SCALE=2.0
EOF

# Configure Apache
echo -e "\n--------------------------------------------"
echo "|configure Apache	                         |"
echo "--------------------------------------------"
sudo mkdir /var/lib/mod_tile
sudo chown _renderd /var/lib/mod_tile
sudo /etc/init.d/renderd restart
sudo /etc/init.d/apache2 restart

# add renderd.conf symlink to conf-enabled
sudo a2enconf renderd.conf
sudo systemctl reload apache2.service

# Create sample leaflet
echo -e "\n--------------------------------------------"
echo "|download sample_leaflet                   |" 
echo "--------------------------------------------"
IP="$(ip -br a | grep -oE '([[:digit:]]{1,3}\.)+[[:digit:]]{1,3}' | grep -v "127\." | head -n1)"
cd /var/www/html
sudo tee index.html <<EOF
<!DOCTYPE html>
<html style="height:100%;margin:0;padding:0;">
<title>Leaflet page with OSM render server selection</title>
<meta charset="utf-8">
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.3/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet@1.3/dist/leaflet.js"></script>
<script src="https://unpkg.com/leaflet-hash@0.2.1/leaflet-hash.js"></script>
<style type="text/css">
.leaflet-tile-container { pointer-events: auto; }
</style>
</head>
<body style="height:100%;margin:0;padding:0;">
<div id="map" style="height:100%"></div>
<script>
//<![CDATA[
var map = L.map('map').setView([53.5568, 8.5898], 13);

L.tileLayer('http://$IP/map/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 20,
}).addTo(map);


var hash = L.hash(map)
//]]>
</script>
</body>
</html>
EOF

echo "generated sample_leaflet.html with ip: $IP"
echo "if the ip is wrong you need to change it manually"

# Setup auto update
echo -e "\n--------------------------------------------"
echo "|Setup auto update of map files            |" 
echo "--------------------------------------------"

sudo -u _renderd osm2pgsql-replication init -d gis --osm-file $pathOfPbf

sudo mkdir /var/log/tiles
sudo chown _renderd /var/log/tiles

sudo tee /usr/local/sbin/expire_tiles.sh <<EOF
#!/bin/bash
render_expired --map=s2o -n=15 --min-zoom=13 --max-zoom=20 -s /run/renderd/renderd.sock -t /var/lib/mod_tile/ < /var/cache/renderd/dirty_tiles.txt
rm /var/cache/renderd/dirty_tiles.txt
EOF


sudo tee /usr/local/sbin/update_tiles.sh <<EOF
#!/bin/bash
osm2pgsql-replication update -d gis --post-processing /usr/local/sbin/expire_tiles.sh --max-diff-size 10  --  -G --hstore --tag-transform-script /home/$USER/src/openstreetmap-carto/openstreetmap-carto.lua -C 15000 --number-processes 12 -S /home/$USER/src/openstreetmap-carto/openstreetmap-carto.style --expire-tiles=1-20 --expire-output=/var/cache/renderd/dirty_tiles.txt
EOF

sudo chmod ugo+x /usr/local/sbin/update_tiles.sh
sudo chmod ugo+x /usr/local/sbin/expire_tiles.sh

sudo tee /etc/systemd/system/tile-server-update.service<<EOF
#/etc/systemd/system/tile-server-update.service

[Unit]
Description=Updates OSM map data
Wants=network.target
After=network-online.target

[Service]
Type=exec
User=_renderd
ExecStart=/usr/local/sbin/update_tiles.sh
EOF

sudo tee /etc/systemd/system/tile-server-update.timer<<EOF
#/etc/systemd/system/tile-server-update.timer

[Unit]
Description=Trigger tile-server Update every day

[Timer]
OnCalendar=daily
AccuracySec=12h
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now tile-server-update.timer

# Setup auto update
echo -e "\n--------------------------------------------"
echo "|Setup monitoring with Munin               |" 
echo "--------------------------------------------"

sudo apt -y install munin-node munin libcgi-fast-perl libapache2-mod-fcgid

sudo tee -a /etc/munin/munin.conf <<EOF
dbdir /var/lib/munin
htmldir /var/cache/munin/www
logdir /var/log/munin
rundir /var/run/munin
EOF

sudo sed -i s/Require\ local/Require\ all\ granted/g /etc/munin/apache24.conf

sudo ln -s /usr/share/munin/plugins/mod_tile* /etc/munin/plugins/
sudo ln -s /usr/share/munin/plugins/renderd* /etc/munin/plugins/

sudo -u munin munin-cron
sudo systemctl restart munin-node.service
sudo systemctl restart apache2.service


endTime=$(date +%s)
timeTaken=$((endTime - startTime))

echo -e "\n---------------------------------------"
echo "|done it took $timeTaken seconds |"
echo "---------------------------------------"
echo -e "You can checkout the map under http://$IP/ and \n monitoring can be found under http://$IP/munin/" | cowsay -f stegosaurus
