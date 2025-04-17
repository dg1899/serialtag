#!/bin/bash


cathelp() {
  echo "Uso: $0 [-i inputdir_xml ] [-o music_dir ] [-c config_dir ] [-l log_file]"

  echo  -e " quando passi altre opzioni oltre -c config-dir  stai riscrivendo le opzioni configurate nel file .conf ma non saranno salvate. \n \n
            il file di configurazone viene rilevato in automatico fino a due directory sotto la directory principale oppure si può specificare un percorso con l'opzione -c "

  exit 1
}


beet_tag_single() {

      beet -vv import -s  -q --search-id="$release_id" "$fileforbeets"

}





xml_dir=""
music_dir=""
config_dir=""
solo_cantante_dir=""
beet_tag="no"
beet_tag_single="no"
check_noalbum="yes"
mv_file="no"
if config_dir_find=$(find "./"  -mindepth 1 -maxdepth 3 -type f  -iname  "*.conf"  2>/dev/null )  ; then
 config_dir="$config_dir_find"
else
config_dir=""
fi





while getopts ":i:o:c:hnsmtd:" options ; do

case "$options" in

n)    check_noalbum=no
   ;;

m) mv_file=yes
   ;;

i )
   xml_dir=$OPTARG
   ;;

s )
   beet_tag_single=yes
   ;;

o )
   music_dir=$OPTARG
   ;;

c )
   config_dir=$OPTARG
   ;;

d ) solo_cantante_dir=$OPTARG

   ;;

\? )
      echo "Invalid option: -$OPTARG" >&2
      cathelp
;;
    : )
      echo "Option -$OPTARG requires an argument." >&2
      cathelp
      ;;
    h )
     cathelp
      ;;

esac
done

shift $((OPTIND -1))

if   [ -z  "$music_dir" ]  || [ -z  "$xml_dir" ]; then

cathelp
#echo "aggiunto"
fi



source "$config_dir"



# Funzione per verificare se un cantante è nella lista dei cantanti specificati
is_solo_cantante() {
  local cantante="$1"
  if [ -n "$solo_cantante_dir" ]; then
    for nome in $(echo "$solo_cantante_dir" | tr ',' '\n'); do
      if [[ "$cantante" == "$nome" ]]; then
        return 0
      fi
    done
    return 1
  else
    return 0
  fi
}






# File contenente la lista dei cantanti da escludere (uno per riga)
escludi_file="$music_dir/escludi.txt"



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





#inizio ciclo for
for artist_dir in "$xml_dir"/* ; do





# # Assicurati che stiamo lavorando solo con le directory
 if [ -d "$artist_dir" ]; then
#    # Ottieni il nome della directory corrente
   artist_name=$(basename "$artist_dir")
#echo  "cartella beet: $artist_name"

# Verifica se il cantante è nella lista di esclusione
    if is_escluso "$artist_name"; then
      echo "Escluso: $artist_name"
        continue
    fi


    # Verifica se il cantante è nella lista dei cantanti specificati
    if ! is_solo_cantante "$artist_name"; then
      echo "Saltato: $artist_name"
      continue
    fi






# Inizio ciclo for per ogni file XML nella directory dell'artista
    for file in "$artist_dir"/*; do


# Usa  xmllint per estrarre i titoli




titles=$(xmllint --xpath '//*[local-name()="title"]/text()' "$file" 2>/dev/null )

if [ $? -ne 0 ] || [ -z "$titles" ]; then
#        echo "Errore nell'estrazione dei titoli dal file" "$file" >> "$log_file"
        continue
      fi

#estraggo id del album

release_id=$(grep -oP '(?<=<recording id=")[^"]+' "$file")
echo "recording id: $release_id"
#echo "$release_id"









    files_moved=$(find "$artist_music_dir" -mindepth 1  -maxdepth 1 -type f  -iname "*$title*" -exec cp  -t   "$album_dir" {} + 2>/dev/null ;  )


   if [  "$beet_tag" = "yes" ]; then
    beet_tag
   fi



done
echo "ho letto i file da "$xml_dir" e ho riordinato la cartella "$music_dir""
#echo "script terminato puoi trovare i log in "$log_file""
