#!/bin/bash

echo "Content-type: text/html"
echo ""
echo "<h1>LISTE DES .DEB </h1>"

dossier="/var/cache/apt/archives"

# Vérifier que le dossier existe
if [ ! -d "$dossier" ]; then
    echo "<p>Le dossier $dossier n'existe pas.</p>"
    exit 1
fi

# Prendre tous les .deb
liste=$(ls "$dossier" | grep ".deb$")


#copier tous les .deb dans /var/www/html à fin de télécharger
cp $dossier/*.deb  /var/www/html


dest="/var/www/html"
for fichier in "$dest"/*.deb ; do
 	 nom_fichier=$(basename $fichier)
 	echo "<a href=\"/$nom_fichier\" download>Download : $nom_fichier</a><br>"
done


