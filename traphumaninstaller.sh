#!/bin/bash

apt-get update
apt-get install apache2 -my
apt-get install php7.0 libapache2-mod-php -my
service apache2 restart
apt-get install mysql-server mysql-client -my
mysqladmin -u root password "rootpasswordmysql"
apt-get install php7.0-mysql -my
apt-get install php7.0-gd php7.0-xml php7.0-mbstring php7.0-zip -my
a2enmod rewrite
echo "<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
	<Directory /var/www/html>
	 AllowOverride All
         RewriteEngine On
         RewriteBase /
         RewriteCond %{REQUEST_FILENAME} !-f
         RewriteCond %{REQUEST_FILENAME} !-d
         RewriteRule ^(.*)$ index.php?q=$1 [L,QSA]
      </Directory>
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf
service apache2 restart
php -r "readfile('https://s3.amazonaws.com/files.drush.org/drush.phar');" > drush && chmod +x drush && mv drush /usr/local/bin
rm -R /var/www/html/*
drush dl drupal --destination=/var/www --drupal-project-rename=html -y
cd /var/www/html
mysql -uroot -prootpasswordmysql -e "CREATE DATABASE drupal;"
mysql -uroot -prootpasswordmysql -e "CREATE USER 'traphumanuser'@'localhost' IDENTIFIED BY 'traphumanuser';"
mysql -uroot -prootpasswordmysql -e "GRANT ALL PRIVILEGES ON drupal.* TO 'traphumanuser'@'localhost';"
mysql -uroot -prootpasswordmysql -e "FLUSH PRIVILEGES";
drush si --db-url="mysql://traphumanuser:traphumanuser@localhost/drupal" --account-name=admin --account-pass=traphuman --locale=es -y
chmod 777 /var/www/html/sites/default/files/ -R
drush en admin_toolbar admin_toolbar_tools -y
drush cr
mkdir /var/www/html/modules/custom
cd /var/www/html/modules/custom
apt-get install git curl unzip -my
git clone https://github.com/traphuman/traphuman.git
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
drush dl swiftmailer
cd /var/www/html
composer require "swiftmailer/swiftmailer":"~5.4.5"
drush en traphuman -y
composer require drupal/console:~1.0 --prefer-dist --optimize-autoloader --sort-packages
vendor/bin/drupal user:role add admin htdirector
drush cr
