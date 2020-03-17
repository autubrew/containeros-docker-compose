#!/usr/bin/env bash

#
# This file should be used to prepare and run your WebProxy after set up your .env file
# Source: https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion
#

# 1. Check if .env file exists
if [ -e .env ]; then
    source .env
else 
    echo "It seems you didn´t create your .env file, so we will create one for you."
    cp .env.sample .env
    # exit 1
fi

# 2. Create docker network
docker network create $NETWORK $NETWORK_OPTIONS

# 3. Verify if second network is configured
if [ ! -z ${SERVICE_NETWORK+X} ]; then
    docker network create $SERVICE_NETWORK $SERVICE_NETWORK_OPTIONS
fi

# 4. Download the latest version of nginx.tmpl
# curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > nginx.tmpl

# 5. Use maven to build .jar file
# docker run -it --rm --name $ORGANIZATION-maven-build -v "${pwk}/api/DockerBack":/usr/src/mymaven -w /usr/src/mymaven maven:3.3-jdk-8 mvn clean package

# 6. Update local images and rebuild custom images
docker-compose pull
docker-compose build

# 7. Add any special configuration if it's set in .env file

# Check if user set to use Special Conf Files
if [ ! -z ${USE_NGINX_CONF_FILES+X} ] && [ "$USE_NGINX_CONF_FILES" = true ]; then

    # Create the conf folder if it does not exists
    mkdir -p $NGINX_FILES_PATH/conf.d

    # Copy the special configurations to the nginx conf folder
    cp -R ./nginx/conf.d/* $NGINX_FILES_PATH/conf.d

    # Copy the nginx.conf to the container's /etc/nginx folder
    cp ./nginx/nginx.conf $NGINX_FILES_PATH/

    # Check if there was an error and try with sudo
    if [ $? -ne 0 ]; then
        sudo cp -R ./conf.d/* $NGINX_FILES_PATH/conf.d
    fi

    # If there was any errors inform the user
    if [ $? -ne 0 ]; then
        echo
        echo "#######################################################"
        echo
        echo "There was an error trying to copy the nginx conf files."
        echo "The proxy will still work with default options, but"
        echo "the custom settings your have made could not be loaded."
        echo 
        echo "#######################################################"
    fi
fi

mkdir -p $DB_FILES_PATH
cp -R ./db/my.cnf $DB_FILES_PATH/ 

# 8. Start proxy

# Check if you have multiple network
if [ -z ${SERVICE_NETWORK+X} ]; then
    docker-compose up -d
else
    docker-compose -f docker-compose-multiple-networks.yml up -d
fi

exit 0
