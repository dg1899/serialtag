#!/bin/bash

# File contenente la lista dei cantanti da escludere (uno per riga)
escludi_file="escludi.txt"

# Percorso principale
main_dir="cartella"

# Legge il file di esclusione e lo converte in un array
escludi_array=()
while IFS= read -r cantante; do
    escludi_array+=("$cantante")
done < "$escludi_file"

# Funzione per verificare se un cantante è nella lista di esclusione
is_escluso() {
    local cantante="$1"
    for escluso in "${escludi_array[@]}"; do
        if [[ "$escluso" == "$cantante" ]]; then
            return 0
        fi
    done
    return 1
}

# Itera su tutte le sottocartelle nel percorso principale
for cantante_dir in "$main_dir"/*/; do
    cantante=$(basename "$cantante_dir")

    # Verifica se il cantante è nella lista di esclusione
    if is_escluso "$cantante"; then
        echo "Escluso: $cantante"
        continue
    fi

    # Sposta le canzoni nella cartella del cantante
    for album_dir in "$cantante_dir"/*/; do
        if [[ -d "$album_dir" ]]; then
            mv "$album_dir"/* "$cantante_dir"
            rmdir "$album_dir" # Elimina la cartella dell'album se vuota
        fi
    done
done
