#!/bin/bash

local_folder="$HOME/Maildir"
remote_server="tine@192.168.59.130"
remote_folder="backup/critical"
backup_mode="$1"

perform_incremental_backup() {
    local source_dir=$1
    local dest_dir=$2
    echo "Performing incremental backup..."
    sudo rdiff-backup --force $source_dir $remote_server::$dest_dir
}

perform_mirror_backup() {
    local source_dir=$1
    local dest_dir=$2
    echo "Performing mirror backup..."
    sudo rsync -avz -e ssh $source_dir $remote_server:$dest_dir
}

for user in /home/*; do
    # Preveri, če je element dejansko imenik
    echo "Checking user: $user"
    if [[ -d $user ]]; then
        local_folder="$user/Maildir"
        # Preveri, če Maildir imenik obstaja
        if [[ -d $local_folder ]]; then
            # Ustvari imenik za varnostno kopiranje ce ne obstaja
            backup_dir="$remote_folder/${user##*/}"
            if [ ! -d "$backup_dir" ]; then
                mkdir -p "$backup_dir"
            fi
            # Izvedi varnostno kopiranje glede na izbran način
            if [ "$backup_mode" == "incremental" ]; then
                perform_incremental_backup "$local_folder" "$backup_dir"
            elif [ "$backup_mode" == "mirror" ]; then
                perform_mirror_backup "$local_folder" "$backup_dir"
            else
                echo "Invalid backup mode. Please specify either 'incremental' or 'mirror'."
                exit 1
            fi
            # Preveri, če je bilo varnostno kopiranje uspešno
            if [ $? -eq 0 ]; then
                echo "Backup for $user completed successfully."
            else
                echo "Backup for $user failed. Please check the error message above."
            fi
        fi
    fi
done
