#!/bin/bash

# Funzione per mostrare l'uso dello script
function usage() {
    echo "Usage: $0 'Nome Cantante' 'Cartella di Salvataggio'"
    exit 1
}

while getopts ":u" options; do
  case "$options" in

\? )
      echo "Invalid option: -$OPTARG" >&2
      ;;

    u )
      while IFS=':' read -r CHOICE CARTELLA_SALVATAGGIO; do
        echo "CHOICE: $CHOICE"
        echo "CARTELLA_SALVATAGGIO: $CARTELLA_SALVATAGGIO"
        # You can perform your desired actions here using $CHOICE and $CARTELLA_SALVATAGGIO

















# Scaricare le release dell'artista scelto
RELEASES=$(curl -s "https://musicbrainz.org/ws/2/release?artist=${CHOICE}&limit=100&fmt=json")

# Estrarre ID e titoli delle release usando jq
RELEASE_LIST=$(echo "$RELEASES" | jq -r '.releases[] | "\(.id) \(.title)"')

# Scaricare ogni release come file XML
while read -r line; do
    RELEASE_ID=$(echo "$line" | awk '{print $1}')
    RELEASE_TITOLO=$(echo "$line" | cut -d' ' -f2- | sed 's/[\/:*?"<>|]/_/g')  # Sostituire caratteri non validi per il file system
    curl -s "https://musicbrainz.org/ws/2/release/${RELEASE_ID}?inc=recordings&fmt=xml" -o "${CARTELLA_SALVATAGGIO}/${CANTANTE}/${RELEASE_TITOLO}.xml"
sleep 0.5
done <<< "$RELEASE_LIST"

done < artisti.txt
    ;;
esac
exit 1
done

# Controllo del numero di argomenti
if [ "$#" -ne 2 ]; then
    usage
fi

# Parametri dello script
CANTANTE="$2"
CARTELLA_SALVATAGGIO="$1"

# Creare la cartella di salvataggio se non esiste
# mkdir -p "${CARTELLA_SALVATAGGIO}/${CANTANTE}"

#verifica che la cartlla sia presente

 if [ -d "${CARTELLA_SALVATAGGIO}/${CANTANTE}" ]; then

# Ricerca dell'artista su MusicBrainz
RESPONSE=$(curl -s "https://musicbrainz.org/ws/2/artist/?query=${CANTANTE}&limit=10&fmt=json")

# Estrarre informazioni dell'artista usando jq
ARTISTI=$(echo "$RESPONSE" | jq -r '.artists[] | "\(.id) \(.name) \(.disambiguation // "No additional info")"')

# Se non ci sono risultati, uscire
if [ -z "$ARTISTI" ]; then
    echo "Nessun artista trovato per il nome: "$CANTANTE""
    exit 1
fi
else
echo "cartella "$CARTELLA_SALVATAGGIO/$CANTANTE" non trovata uscita"
exit 1
fi

# Creare il menu interattivo usando dialog
MENU=()
while read -r line; do
    ID=$(echo "$line" | awk '{print $1}')
    NOME=$(echo "$line" | awk '{print $2}')
    DISAMBIGUAZIONE=$(echo "$line" | cut -d' ' -f3-)
    MENU+=("$ID" "$NOME - $DISAMBIGUAZIONE")
done <<< "$ARTISTI"

CHOICE=$(dialog --menu "Scegli l'artista" 0 0 0 "${MENU[@]}" 3>&1 1>&2 2>&3)

# Se l'utente ha annullato l'operazione, uscire
if [ $? -ne 0 ]; then
    read -p  "immettere id cantante da musicbrainz altrimenti terminare lo script :" CHOICE
fi

# Scaricare le release dell'artista scelto
RELEASES=$(curl -s "https://musicbrainz.org/ws/2/release?artist=${CHOICE}&limit=100&fmt=json")

# Estrarre ID e titoli delle release usando jq
RELEASE_LIST=$(echo "$RELEASES" | jq -r '.releases[] | "\(.id) \(.title)"')

# Scaricare ogni release come file XML
while read -r line; do
    RELEASE_ID=$(echo "$line" | awk '{print $1}')
    RELEASE_TITOLO=$(echo "$line" | cut -d' ' -f2- | sed 's/[\/:*?"<>|]/_/g')  # Sostituire caratteri non validi per il file system
    curl -s "https://musicbrainz.org/ws/2/release/${RELEASE_ID}?inc=recordings&fmt=xml" -o "${CARTELLA_SALVATAGGIO}/${CANTANTE}/${RELEASE_TITOLO}.xml"
sleep 0.5
done <<< "$RELEASE_LIST"

# Salvare i dettagli nel file di testo

echo "${CHOICE}:${CARTELLA_SALVATAGGIO}/${CANTANTE}" >> "$CARTELLA_SALVATAGGIO"/artisti.txt

echo "Download completato. Informazioni salvate in artisti.txt."
