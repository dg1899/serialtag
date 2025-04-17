#!/bin/bash

cartella="$1"
# Verifica che sia stato passato un argomento
if [ -z "$1" ]; then
  echo "Uso: $0 percorso_del_file.xml"
  exit 1
fi



#inizio ciclo for
for file in "$cartella"/* ; do
# Verifica che il file sia un file XML
if [[ "$file" == * ]]; then
    echo  -e "Processando il file: $file\n "



# Usa xmllint per estrarre i titoli
titles=$(xmllint --xpath '//*[local-name()="title"]/text()' "$file")


# Verifica se xmllint ha estratto i titoli con successo
if [ $? -eq 0 ]; then
      # Stampa i titoli
      echo -e  "Titoli trovati nel file $file:\n"
      echo "$titles"
 else
      echo "Errore nell'estrazione dei titoli dal file $file"
    fi
  echo ""

else

 echo  -e "Il file $file non è un file XML, saltato.\n"
  fi
done
