#!/bin/bash

# File contenente la lista dei cantanti da escludere (uno per riga)
escludi_file="escludi.txt"

# Percorso principale
main_dir="$1"

# Legge il file di esclusione e lo memorizza in una variabile
esclusi=$(cat "$escludi_file")

# Itera su tutte le sottocartelle nel percorso principale
for cantante_dir in "$main_dir"/*/; do
    cantante=$(basename "$cantante_dir")

    # Verifica se il cantante è nella lista di esclusione
    if echo "$esclusi" | grep -q "^$cantante$"; then
        echo "Escluso: $cantante"
        continue
    fi

    # Sposta le canzoni nella cartella del cantante
    for album_dir in "$cantante_dir"/*/; do
        mv "$album_dir"/* "$cantante_dir" 2>/dev/null
        rmdir "$album_dir" 2>/dev/null # Elimina la cartella dell'album se vuota
    done
done
