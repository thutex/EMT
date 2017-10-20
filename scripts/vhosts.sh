#!/bin/bash
TEXTDOMAIN=virtualhost

#action can be create, delete
action=$1
domain=$2
email='mail@example.org'
sitesEnable='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'
userDir='/var/www/'
sitesAvailabledomain=$sitesAvailable$domain.conf

### don't modify from here unless you know what you are doing ####

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
	then
		echo $"You need to prompt for action (create or delete) -- Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide domain"
	exit 1;
done

rootDir=$userDir$domain

if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain already exists.\nPlease Try Another one"
			exit;
		fi

		### check if directory exists or not
		if ! [ -d $rootDir ]; then
			### create the directory
			mkdir $rootDir
			### give permission to root dir
			chmod 755 $rootDir
			### write test file in the new domain dir
			if ! echo "<?php echo phpinfo(); ?>" > $rootDir/phpinfo.php
			then
				echo $"ERROR: Not able to write in file $rootDir/phpinfo.php. Please check permissions"
				exit;
			else
				cp -r /var/www/skel/* $rootDir
				echo $"Added default content to $rootDir"
			fi
		fi

		### create virtual host rules file
		if ! echo "
		<VirtualHost *:80>
			ServerAdmin $email
			ServerName $domain
			ServerAlias www.$domain
			DocumentRoot $rootDir
			<Directory />
				AllowOverride All
			</Directory>
			<Directory $rootDir>
				Options Indexes FollowSymLinks
				AllowOverride all
				Require all granted
			</Directory>
			ErrorLog /var/www/logs/$domain-error.log
			LogLevel error
			CustomLog /var/www/logs/$domain-access.log combined
		</VirtualHost>
		
                <VirtualHost *:80>
                        ServerAdmin $email
                        ServerName webmail.$domain
                        DocumentRoot /var/www/html/webmail
                        <Directory />
                                AllowOverride All
                        </Directory>
                        <Directory /var/www/html/webmail>
                                Options Indexes FollowSymLinks
                                AllowOverride none
                                Require all granted
                        </Directory>
                        ErrorLog /var/www/logs/webmail.$domain-error.log
                        LogLevel error
                        CustomLog /var/www/logs/webmail.$domain-access.log combined
                </VirtualHost>
		<IfModule mod_ssl.c>
	        <VirtualHost *:443 >
                ServerName $domain:443
                ServerAlias www.$domain
                ServerAdmin tech@peeters.io
                UseCanonicalName Off
                DocumentRoot /var/www/$domain
                ErrorLog /var/www/logs/$domain-error.log
                CustomLog /var/www/logs/$domain-access.log combined
                SSLEngine on
                SSLVerifyClient none  
                SSLCertificateFile    /etc/letsencrypt/live/$domain/cert.pem
                SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem
                SSLCertificateChainFile /etc/letsencrypt/live/$domain/fullchain.pem
        	<Directory /var/www/$domain>
                SSLRequireSSL
                Options -Includes +ExecCGI
                </Directory>
	        </VirtualHost>
        	<VirtualHost *:443>
                ServerAdmin $email
                ServerName webmail.$domain
                DocumentRoot /var/www/html/webmail
                <Directory />
                AllowOverride All
                </Directory>
                <Directory /var/www/html/webmail>
                Options Indexes FollowSymLinks
                AllowOverride none
                Require all granted
                </Directory>
                ErrorLog /var/www/logs/webmail.$domain-error.log
                LogLevel error
                CustomLog /var/www/logs/webmail.$domain-access.log combined
		SSLEngine on
                SSLVerifyClient none   
                SSLCertificateFile    /etc/letsencrypt/live/webmail.$domain/cert.pem
                SSLCertificateKeyFile /etc/letsencrypt/live/webmail.$domain/privkey.pem
                SSLCertificateChainFile /etc/letsencrypt/live/webmail.$domain/fullchain.pem

                </VirtualHost>

</IfModule>" > $sitesAvailabledomain
		then
			echo -e $"There is an ERROR creating $domain file"
			exit;
		else
			echo -e $"\nNew Virtual Host Created\n"
		fi

		if [ "$owner" == "" ]; then
			chown -R $(whoami):$(whoami) $rootDir
		else
			chown -R $owner:$owner $rootDir
		fi

		### enable website
		a2ensite $domain

		### restart Apache
		/etc/init.d/apache2 reload

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootDir"
		exit;
	else
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit;
		else
			### disable website
			a2dissite $domain

			### restart Apache
			/etc/init.d/apache2 reload

			### Delete virtual host rules files
			rm $sitesAvailabledomain
		fi

		### check if directory exists or not
		if [ -d $rootDir ]; then
			echo -e $"Delete host root directory ? (y/n)"
			read deldir

			if [ "$deldir" == 'y' -o "$deldir" == 'Y' ]; then
				### Delete the directory
				rm -rf $rootDir
				echo -e $"Directory deleted"
			else
				echo -e $"Host directory conserved"
			fi
		else
			echo -e $"Host directory not found. Ignored"
		fi

		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $domain"
		exit 0;
fi
