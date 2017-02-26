#!/bin/bash

#nom du jour de la semaine
now=$(/bin/date +"%d-%m-%Y")
jour=$(date +%A)
destination="/home/backup/$jour"
repertoire="/home/www"
red='\033[0;31m'
green='\033[0;32m'
cyan='\033[0;36m'
blue='\033[0;34m'
reset='\033[0m'

if [ ! "$(ls -A /home/backup/)" ]
then
	#Creation des sous dossier par jour de semaine si besoin
	printf "================= ${cyan}CREATION DES REPERTOIRES${reset} =================\n"
	for x in lundi mardi mercredi jeudi vendredi samedi dimanche 
	do
		/bin/mkdir /home/backup/$x
		if [ "$?" -eq "0" ]
		then
			printf "${green}success:${reset} Le répertoire $x a été créé\n\n"
		else
			printf "${red}error:${reset} Attention, e répertoire $x n'a pas été créé\n\n"
		fi
	done
else
	#Supprime tar.gz f'il en trouve
	archives=$(find $destination/*.tar.gz | wc -l)
	if [ $archives -gt 0 ]
	then
        	printf "================= ${cyan}SUPPRESSION DES ARCHIVES${reset} =================\n"
        	/bin/rm -r $destination/*.tar.gz
		if [ "$?" -eq "0" ]
		then
			printf "${green}success:${reset} Les archives précédentes sont supprimées\n\n"
		else
			printf "${red}error:${reset} Attention, les archives n'ont pas été supprimées\n\n"
		fi
	fi
fi

if [ -d $destination ]
then
	#Backup BDD
	printf "================= ${cyan}COPIE DES BDD${reset} =================\n"

	databases=$(/usr/bin/mysql -u geekoun -pMRsW39vA.c4+FY -e "SHOW databases;" | grep -Ev "(Database|information_schema|mysql|performance_schema)")
        for db in $databases;
	do
		printf "${blue}__BDD ${db^^}__${reset}\n"
		/usr/bin/mysqldump -u $user -p$pass --force --opt --skip-lock-tables --events --databases $db | gzip > $destination/$db.sql.gz
		if [ "$?" -eq "0" ]
        	then
        		printf "        ${green}success:${reset} La copie de la BDD est un succès\n"
        	else
             		printf "        ${red}error:${reset} Attention, la copie de la BDD a échoué\n"
        	fi

		printf "${blue}__COPIE BDD ${db^^} DISTANT__${reset}\n"
        	/usr/bin/rsync --rsync-path="/usr/bin/rsync" -az --delete -e 'ssh -p $port' --ignore-errors $destination/$db.sql.gz $user@$adresse:/volume1/save/$jour
		if [ "$?" -eq "0" ]
        	then
                	printf "        ${green}success:${reset} La copie distante de la BDD est un succès\n\n"
        	else
                	printf "        ${red}error:${reset} La copie distante de la BDD a échoué\n\n"
        	fi
	done

	for site in $repertoire/*;
	do
		if [ -d $site ]
		then
			dir=${site##*/}

			printf "================= ${cyan}${dir^^}${reset} =================\n"

			#Backup sur serveur local
			printf "${blue}__RSYNC BACKUP__${reset}\n"
			/usr/bin/rsync -az --delete --ignore-errors $site $destination
			if [ "$?" -eq "0" ]
			then
				printf "	${green}success:${reset} La copie est un succès\n"
			else
				printf "	${red}error:${reset} Attention, la copie a échoué\n"
			fi

			#Compression sur serveur local
			printf "${blue}__COMPRESSION__${reset}\n"
			cd $destination;
			/bin/tar -zcf $dir-$now.tar.gz $dir
			if [ "$?" -eq "0" ]
			then
				printf "	${green}success:${reset} La compression est un succès\n"
			else
				printf "	${red}error:${reset} Attention, la compression a échoué\n"
			fi

			#Backup sur server distant
			printf "${blue}__COPIE DISTANTE__${reset}\n"
			/usr/bin/rsync --rsync-path="/usr/bin/rsync" -az --delete -e 'ssh -p $port' --ignore-errors $site $user@$adresse:/volume1/save/$jour
			if [ "$?" -eq "0" ]
			then
				printf "  	${green}success:${reset} La copie distante est un succès\n\n"
			else
				printf "	${red}error:${reset} La copie distante a échoué\n\n"
			fi
		else
			printf "${red}error:${reset} Attention, le répertoire a copier n'existe pas\n"
		fi
	done
else
	printf "${red}error:${reset} Attention, le répertoire de sauvegarde n'existe pas\n"
fi
