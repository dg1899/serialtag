#!/bin/bash

cd  /home/diego/Musica/
ls -d */ | cat | while  IFS= read -r line; do mkdir /home/diego/Musica/mvmp3/"$line"
done
