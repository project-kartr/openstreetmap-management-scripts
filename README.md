# README OSM
## English

The OSM subproject of the Kartr project consists of scripts that are built to set up an OSM rendering environment. It includes:

- A PostgreSQL database with OSM data
- Renderd for rendering the OSM data into tiles
- Apache for delivering the tiles under /
- Systemd Unitfiles for regular updates of OSM data and tile rerendering
- Munin for system monitoring under /munin/

## Note

The script packs some files into the current user directory. These files are required, and it is recommended to execute the script in a newly created user directory.

## Pre-Rendering

To prevent the need to render all tiles after setting up the server, commonly used tiles can be pre-rendered. For this purpose, the script from https://github.com/alx77/render_list_geo.pl can be used most easily. Unlike renderd, the script can handle geo-coordinates. We have included some sample scripts for pre-rendering, called preRender*.sh.

## Reindexing

When updating the tiles, the collation of the database may no longer be up-to-date. To fix this error, the reindex.sh script exists, which reindexes the database and updates the collation.


## LICENSE

The Source Code from this project is subject to the terms of the MIT License.

## German

Das Teilprojekt OSM vom Projekt Kartr besteht aus Skripten, die dafür gebaut sind, eine OSM-Render-Umgebung aufzusetzen. Es inkludiert:
- eine pgsql-Datenbank mit den OSM-Daten
- renderd zum Rendern der OSM-Daten in Tiles
- apache zum ausliefern der Tiles unter /
- systemd-Unitfiles zur regelmäßigen Aktualisierung der OSM-Daten und zum Rerendering der Tiles
- munin zum Systemmonitoring unter /munin/

## Note

Das Skript packt einige Dateien in das aktuelle Userverzeichnis. Diese Dateien werden benötigt, es wird empfohlen das Skript in einem eigens dafür angelegten User auszuführen.

## Pre-Rendering

Um zu verhindern, dass nach dem Aufsetzen des Servers alle aufgerufene Tiles gerendert werden müssen lassen sich erwartet häufig genutzte Tiles vorrendern.

Dafür lässt sich das Skript von https://github.com/alx77/render_list_geo.pl am einfachsten Benutzen. Das Skript kann im gegensatz zu renderd selbst mit Geo-Koordinaten umgehen. Wir haben ein paar Beispielskripte preRender*.sh beigelegt.

## Reindexing

Beim Updaten der Tiles kann es vorkommen, dass die Collation der Datenbank nicht länger aktuell ist. Um diesen Fehler zu beheben existiert das Skript *reindex.sh*, welches die Datenbank neu indiziert und anschließend die Collation aktualisiert.


## LICENSE

Der Source-Code dieses Projekts steht unter der MIT Lizenz.
