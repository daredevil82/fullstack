#!/bin/bash

# Script to set up a Django project with MySQL & PostgreSQL support on a Vagrant
# deveopment instance

# Edit variables below to fit project

PROJECT_NAME=fullstack
DJANGO_PROJECT_NAME=project

DB_USER=dev
DB_PASSWORD=default123
LOCAL_SETTINGS_PATH="/$DJANGO_PROJECT_NAME/settings/local.py"

DB_NAME=$PROJECT_DIR
VIRTUALENV_DIR=/home/vagrant/.virtualenvs/$PROJECT_DIR
PROJECT_DIR=/home/vagrant/$PROJECT_DIR

export DEBIAN_FRONTEND=noninteractive

PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
    # add PG apt repository
    echo "Adding PG repository to apt"
    echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > "$PG_REPO_APT_SOURCE"

    # Add PGDG repo key
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
fi


# set mysql root password without having to use shell
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_PASSWORD"

# Install apt packages
echo "Installing essentials, python3, mysql and postgres"
apt-get update -y
apt-get upgrade -y
apt-get install -y build-essential python3 python3-dev python3-pip python3-tk libncurses5-dev libffi-dev debconf
apt-get install -y mysql-server-5.6 libmysqlclient18 libmysqlclient-dev postgresql-9.5 postgresql-contrib-9.5 postgresql-server-dev-9.5

echo "Setting up mysql with the following:"
echo "  USERNAME: $DB_USER"
echo "  PASSWORD: $DB_PASSWORD"
echo "  DATABASE: $PROJECT_NAME"
echo ""

# create mysql db with username/password with all privileges
mysql -u root -p$DB_PASSWORD -e "create user '$DB_USER'@'localhost' identified by '$DB_PASSWORD'"
mysql -u root -p$DB_PASSWORD -e "create database $PROJECT_NAME"
mysql -u root -p$DB_PASSWORD -e "grant all privileges on $PROJECT_NAME.* to '$DB_USER'@'localhost'"
mysql -u root -p$DB_PASSWORD -e "flush privileges"

echo "Setting up Postgres with the following:"
echo "  USERNAME: $DB_USER"
echo "  PASSWORD: $DB_PASSWORD"
echo "  DATABASE: $PROJECT_NAME"
echo ""

PG_CONF="/etc/postgresql/9.5/main/postgresql.conf"
PG_HBA="/etc/postgresql/9.5/main/pg_hba.conf"

# Edit pg conf to listen to * addresses
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Set default encoding
echo "client_encoding = utf8" >> "$PG_CONF"

# Copy pg_hba.conf file for auth settings & restart server
service postgresql stop
cp /home/vagrant/fullstack/provision/files/pg_hba.conf "$PG_HBA"
service postgresql restart

# Create user and database
cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD' SUPERUSER CREATEDB;

-- Create database:
CREATE DATABASE $PROJECT_NAME WITH OWNER=$DB_USER LC_COLLATE='en_US.utf8' LC_CTYPE='en_US.utf8' ENCODING='UTF8' TEMPLATE=template0;
EOF

#virtualenv environment setup
if [[ ! -f /usr/local/bin/virtualenv ]]; then
    echo "Creating virtual environment - Downloading pip dependencies"
    pip3 install virtualenv virtualenvwrapper stevedore virtualenv-clone
fi

echo "Creating virtual environment"
su - vagrant -c "/usr/local/bin/virtualenv --python=/usr/bin/python3.4 $VIRTUALENV_DIR && \
    $VIRTUALENV_DIR/bin/pip install -r /home/vagrant/fullstack/requirements.txt"

echo "source /usr/local/bin/virtualenvwrapper.sh" >> /home/vagrant/.bashrc