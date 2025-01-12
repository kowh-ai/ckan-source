#!/bin/bash

CKAN_INI=/etc/ckan/default/ckan.ini

# Start the PostgreSQL CKAN database and update the database
echo "Starting and configuring PostgreSQL..."
service postgresql start 
sudo -u postgres psql -c "CREATE USER ckan_default WITH PASSWORD 'pass';"
sudo -u postgres psql -c "CREATE DATABASE ckan_default WITH OWNER ckan_default;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ckan_default TO ckan_default;"

# Generate the CKAN configuration file
echo "Generating the CKAN configuration file..."
. /usr/lib/ckan/default/bin/activate
mkdir -p /etc/ckan/default
chown -R `whoami` /etc/ckan/
ckan generate config $CKAN_INI

# Start solr, create the CKAN core, download the CKAN schema, restart solr
## TODO: use an environment variable for the CKAN schema version ##
echo "Starting Solr..."
sudo -u solr /opt/solr/bin/solr start --force
mkdir -p /var/solr/data/ckan/conf && chown -R solr /var/solr/data/ckan
echo "Creating the CKAN core and then restarting Solr..."
sudo -u solr /opt/solr/bin/solr create -c ckan
sudo -u solr wget -O /opt/solr/server/solr/ckan/conf/managed-schema.xml https://raw.githubusercontent.com/ckan/ckan/dev-v2.11/ckan/config/solr/schema.xml
sudo -u solr /opt/solr/bin/solr restart

# Start Redis
echo "Starting Redis..."
redis-server /etc/redis/redis.conf

# Create the CKAN Database tables
echo "waiting a bit so Solr has time to load..." ; sleep 3
ckan -c /etc/ckan/default/ckan.ini db init

# Create the CKAN admin user and then make the user a Sys Admin
ckan -c /etc/ckan/default/ckan.ini user add ckan_admin email=ckan_admin@localhost password=test1234
ckan -c /etc/ckan/default/ckan.ini sysadmin add ckan_admin

# Install and configure the Datastore extension
echo "Update the ckan.ini file with the datastore configuration"
ckan config-tool $CKAN_INI "ckan.datastore.write_url = postgresql://ckan_default:pass@localhost/datastore_default"
ckan config-tool $CKAN_INI "ckan.datastore.read_url = postgresql://datastore_default:pass@localhost/datastore_default"

echo "Create the datastore database and user..."
sudo -u postgres psql -c "CREATE USER datastore_default WITH PASSWORD 'pass';"
sudo -u postgres psql -c "CREATE DATABASE datastore_default WITH OWNER datastore_default;"
ckan -c $CKAN_INI datastore set-permissions | sudo -u postgres psql --set ON_ERROR_STOP=1

# echo "Do the beaker token stuff..."
echo "Setting beaker.session.secret in ini file"
ckan config-tool $CKAN_INI "beaker.session.secret=$(python3 -c 'import secrets; print(secrets.token_urlsafe())')"
ckan config-tool $CKAN_INI "WTF_CSRF_SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe())')"
JWT_SECRET=$(python3 -c 'import secrets; print("string:" + secrets.token_urlsafe())')
ckan config-tool $CKAN_INI "api_token.jwt.encode.secret=${JWT_SECRET}"
ckan config-tool $CKAN_INI "api_token.jwt.decode.secret=${JWT_SECRET}"

# echo "Complete configuration and start the XLOADER service..."
ckan config-tool $CKAN_INI "ckan.xloader.api_token=$(ckan -c $CKAN_INI user token add ckan_admin xloader | tail -n 1 | tr -d '\t')"
ckan config-tool $CKAN_INI "ckanext.xloader.site_url=http://ckan-dev:5000"
ckan config-tool $CKAN_INI "ckan.plugins = image_view text_view datatables_view datastore xloader"
ckan -c $CKAN_INI jobs worker &

# Start the CKAN server
echo "Starting the CKAN server..."
ckan -c $CKAN_INI run --host 0.0.0.0 --port 5000 -r

# hang around for a while
while true; do sleep 2000; done