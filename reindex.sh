# This skript is used, when postgres says, that the collation version has changed 
# and that the database needs to be reindexed.

#!/bin/bash
sudo -u _renderd bash -c "psql -d gis -c 'REINDEX DATABASE gis;'"
sudo -u _renderd bash -c "psql -d gis -c 'ALTER DATABASE gis REFRESH COLLATION VERSION;'"

