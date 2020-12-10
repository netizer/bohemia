#!/bin/bash
#ROOT_FOLDER_PATH=/home/ubuntu/Documents/bohemia
# Runs odk_get_data for instance id's not already retrieved.
set -e
source /home/ubuntu/.virtualenvs/bohemia/bin/activate
echo "Started the data retrieval"
cd ~/Documents/bohemia/scripts
# .${ROOT_FOLDER_PATH}/scripts/update_database.R
Rscript update_database.R
echo "ODK data retrieval complete"
deactivate