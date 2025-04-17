#!/bin/bash


cantante_dir=$1

  # Sposta le canzoni nella cartella del cantante
    for album_dir in "$cantante_dir"/*/; do
        if [[ -d "$album_dir" ]]; then
            mv "$album_dir"/* "$cantante_dir"
            rmdir "$album_dir" # Elimina la cartella dell'album se vuota
        fi
    done
