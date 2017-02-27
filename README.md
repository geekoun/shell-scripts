# shell-scripts

Retrouvez mes scripts shell dans cette zone ;-) 

<h2>BACKUP.SH</h2>
<p>
now=$(/bin/date +"%d-%m-%Y") #date d'aujourd'hui
jour=$(date +%A) #nom du jour de la semaine
dest_directory= "/your/dest_backup/" #chemin du dossier backup global
dest="/your/dest_backup/$jour" #chemin du dossier backup par jour
directory="/your/directory/to/save" #chemin à sauvegarder
user_mysql="your_user_name" #identifiant mysql
pass_mysql="your_pass_name" #mot de passe mysql
path_distant="/your/directory/distant/$jour" #chemin du serveur distant
user_distant="your_user_name_distant" #identifiant du serveur distant
pass_distant="your_user_pass_distant" #mot de passe du serveur distant
address_distant="your_address_distant" #adresse du serveur distant
port_distant="your_port_distant" #port du serveur distant
</p>
