#!/bin/bash

cathelp() {
  echo "Uso: $0 [-i inputdir_xml ] [-o music_dir ] [-c config_dir ] [-l log_file]"
  echo -e "Quando passi altre opzioni oltre -c config-dir, stai riscrivendo le opzioni configurate nel file .conf ma non saranno salvate.\n\n
            Il file di configurazione viene rilevato in automatico fino a due directory sotto la directory principale oppure si può specificare un percorso con l'opzione -c."
  exit 1
}

beet_tag() {
  beet -vv import --search-id="$release_id" "$album_dir"
}

beet_tag_single() {
  local release_id="$1" # passa id come parametro
  for fileforbeets in "$artist_music_dir"/*; do
    if [ -f "$fileforbeets" ]; then
      beet -vv import -s -q --search-id="$release_id" "$fileforbeets"
    fi
  done
}

xml_dir=""
music_dir=""
config_dir=""
solo_cantante_dir=""
beet_tag="no"
beet_tag_single="no"
check_noalbum="yes"
mv_file="no"

if config_dir_find=$(find "./" -mindepth 1 -maxdepth 3 -type f -iname "*.conf" 2>/dev/null); then
  config_dir="$config_dir_find"
else
  config_dir=""
fi

while getopts ":i:o:c:hnsmtd:" options; do
  case "$options" in
    t) beet_tag=yes ;;
    n) check_noalbum=no ;;
    m) mv_file=yes ;;
    i) xml_dir=$OPTARG ;;
    s) beet_tag_single=yes ;;
    o) music_dir=$OPTARG ;;
    c) config_dir=$OPTARG ;;
    d) solo_cantante_dir=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2; cathelp ;;
    :) echo "Option -$OPTARG requires an argument." >&2; cathelp ;;
    h) cathelp ;;
  esac
done

shift $((OPTIND - 1))

if [ -z "$music_dir" ] || [ -z "$xml_dir" ]; then
  cathelp
fi

source "$config_dir"

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

escludi_file="$music_dir/escludi.txt"

escludi_array=()
while IFS= read -r cantante; do
  escludi_array+=("$cantante")
done < "$escludi_file"

is_escluso() {
  local cantante="$1"
  for escluso in "${escludi_array[@]}"; do
    if [[ "$escluso" == "$cantante" ]]; then
      return 0
    fi
  done
  return 1
}

for artist_dir in "$xml_dir"/*; do
  if [ -d "$artist_dir" ]; then
    artist_name=$(basename "$artist_dir")

    if is_escluso "$artist_name"; then
      echo "Escluso: $artist_name"
      continue
    fi

    if ! is_solo_cantante "$artist_name"; then
      echo "Saltato: $artist_name"
      continue
    fi

    artist_music_dir="$music_dir/$artist_name"
    mkdir -p "$music_dir/$artist_name"

    for file in "$artist_dir"/*; do
      titles=$(xmllint --xpath '//*[local-name()="title"]/text()' "$file" 2>/dev/null)
      if [ $? -ne 0 ] || [ -z "$titles" ]; then
        continue
      fi

      release_id=$(grep -oP '(?<=<release id=")[^"]*' "$file")
      echo "Release ID: $release_id"

  recording_id_single=$(xmllint --xpath "string(//recording/@id)" "$xml_file_single")

      if [ "$check_noalbum" == "yes" ]; then
        first_title=$(echo "$titles" | sed -n '1p' | tr '[:upper:]' '[:lower:]')
        second_title=$(echo "$titles" | sed -n '2p' | tr '[:upper:]' '[:lower:]')

        if [ "$first_title" == "$second_title" ]; then
          echo "Primo e secondo titolo sono uguali, saltando la creazione della cartella per: $first_title"
          continue
        fi
      fi

      count=0
      while IFS= read -r title; do
        count=$((count + 1))
        if [ "$count" -eq 1 ]; then
          album_dir="$artist_music_dir/$title"
          mkdir -p "$album_dir"
          echo "Creata la cartella: $title"
        else
          if [ "$mv_file" == "yes" ]; then
            files_moved=$(find "$artist_music_dir" -mindepth 1 -maxdepth 1 -type f -iname "*$title*" -exec mv -t "$album_dir" {} + 2>/dev/null)
          else
            files_moved=$(find "$artist_music_dir" -mindepth 1 -maxdepth 1 -type f -iname "*$title*" -exec cp -t "$album_dir" {} + 2>/dev/null)
          fi

          if [ "$beet_tag" == "yes" ]; then
            beet_tag
          fi
        fi
      done <<< "$titles"
    done
  fi

  if [ "$beet_tag_single" == "yes" ]; then
    beet_tag_single "$release_id"
  fi
done

echo "Ho letto i file da \"$xml_dir\" e ho riordinato la cartella \"$music_dir\""
