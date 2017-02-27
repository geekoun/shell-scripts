#!/bin/bash

#------------------------------------------------------
#    Backup journalière avec sauvegarde sur 7 jours
#------------------------------------------------------
#
# Author: Morgan JOURDIN
# Alias: geekoun
# version: 1.0.0
#
# La copie distante fonctionne que si l'on a aussi un dossier contenant 
# les sous-dossiers par nom de jour (lundi, mardi, etc.)
#

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
#Couleur pour custom le texte
red='\033[0;31m'
green='\033[0;32m'
cyan='\033[0;36m'
blue='\033[0;34m'
reset='\033[0m'

if [ ! "$(ls -A $dest_directory)" ] #s'il n'existe pas des sous-dossiers
then
	#Creation des sous dossier par nom de jour de semaine si besoin dans le dossier $dest_directory
	printf "================= ${cyan}CREATION DES REPERTOIRES${reset} =================\n"
	for x in lundi mardi mercredi jeudi vendredi samedi dimanche 
	do
		/bin/mkdir /home/backup/$x
		if [ "$?" -eq "0" ] #test si la création des sous-dossiers c'est bien déroulée
		then
			printf "${green}success:${reset} Le répertoire $x a été créé\n\n"
		else
			printf "${red}error:${reset} Attention, le répertoire $x n'a pas été créé\n\n"
		fi
	done
else #sinon
	#Supprime tar.gz f'il en trouve de la semaine précédente
	archives=$(find $dest/*.tar.gz | wc -l)
	if [ $archives -gt 0 ] #test si des archives précédentes existent
	then
        	printf "================= ${cyan}SUPPRESSION DES ARCHIVES${reset} =================\n"
        	/bin/rm -r $dest/*.tar.gz
		if [ "$?" -eq "0" ] #test si la suppression des archives c'est bien déroulée
		then
			printf "${green}success:${reset} Les archives précédentes sont supprimées\n\n"
		else
			printf "${red}error:${reset} Attention, les archives n'ont pas été supprimées\n\n"
		fi
	fi
fi

if [ -d $dest ] #Si le répertoire de sauvagarde au nom du bon jour existe
then
	#Backup BDD
	printf "================= ${cyan}COPIE DES BDD${reset} =================\n"
	
	#Récupère les noms des BDD souhaitées
	databases=$(/usr/bin/mysql -u $user_mysql -p$pass_mysql -e "SHOW databases;" | grep -Ev "(Database|information_schema|mysql|performance_schema)")
        for db in $databases; #loop qui executera un dump de chaque BDD par leur nom
	do
		printf "${blue}__BDD ${db^^}__${reset}\n"
		#Execution du dump mysql dans le répertoire de backup en question
		/usr/bin/mysqldump -u $user_mysql -p$pass_mysql --force --opt --skip-lock-tables --events --databases $db | gzip > $dest/$db.sql.gz
		if [ "$?" -eq "0" ] #test si la copie est ok
        	then
        		printf "        ${green}success:${reset} La copie de la BDD est un succès\n"
        	else
             		printf "        ${red}error:${reset} Attention, la copie de la BDD a échoué\n"
        	fi

		printf "${blue}__COPIE BDD ${db^^} DISTANT__${reset}\n"
		#Envoi la copie dans le serveur distant
        	/usr/bin/rsync --rsync-path="/usr/bin/rsync" -az --delete -e "ssh -p ${port_distant}" --ignore-errors $dest/$db.sql.gz ${user_distant}@$address_distant:$path_distant
		if [ "$?" -eq "0" ] #Teste si la copie sur le serveur distant est ok
        	then
                	printf "        ${green}success:${reset} La copie distante de la BDD est un succès\n\n"
        	else
                	printf "        ${red}error:${reset} La copie distante de la BDD a échoué\n\n"
        	fi
	done

	for site in $directory/*; #loop sur tous les sous-dossiers du repertoire à sauvegarder
	do
		if [ -d $site ] #Si le sous-dossier existe (on ne sait jamais ;-))
		then
			dir=${site##*/}

			printf "================= ${cyan}${dir^^}${reset} =================\n"

			#Backup sur serveur local
			printf "${blue}__RSYNC BACKUP__${reset}\n"
			#Copie des sous-dossiers et leurs contenus dans le dossier de backup
			/usr/bin/rsync -az --delete --ignore-errors $site $dest
			if [ "$?" -eq "0" ] #Teste si tout c'est bien déroulé
			then
				printf "	${green}success:${reset} La copie est un succès\n"
			else
				printf "	${red}error:${reset} Attention, la copie a échoué\n"
			fi

			#Compression sur serveur local
			printf "${blue}__COMPRESSION__${reset}\n"
			cd $dest;
			#Compression du dossier (à vous de voir ce que vous voulez en faire ;-))
			/bin/tar -zcf $dir-$now.tar.gz $dir
			if [ "$?" -eq "0" ] #Teste si la compression c'est bien déroulée
			then
				printf "	${green}success:${reset} La compression est un succès\n"
			else
				printf "	${red}error:${reset} Attention, la compression a échoué\n"
			fi

			#Backup sur server distant
			printf "${blue}__COPIE DISTANTE__${reset}\n"
			#Envoi la copie dans le serveur distant
			/usr/bin/rsync --rsync-path="/usr/bin/rsync" -az --delete -e "ssh -p ${port_distant}" --ignore-errors $site ${user_distant}@$address_distant:$path_distant
			if [ "$?" -eq "0" ] #Teste si la copie sur le serveur distant est ok
			then
				printf "  	${green}success:${reset} La copie distante est un succès\n\n"
			else
				printf "	${red}error:${reset} La copie distante a échoué\n\n"
			fi
		else
			#Pas de dossier existant pas de copie Oo
			printf "${red}error:${reset} Attention, le répertoire à copier n'existe pas\n"
		fi
	done
else
	#Pas de répertoire par nom de jour pas de copie Oo
	printf "${red}error:${reset} Attention, le répertoire de sauvegarde n'existe pas\n"
fi
