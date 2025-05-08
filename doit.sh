#!/bin/bash -x

# Set the CKAN version
CKAN_VERSION=2.11.3
XLOADER_VERSION=2.1.0

# Stop and remove the existing Docker container if there is one runnin at all
CONTAINER_RUNNING=$(docker ps -a -q -f name=ckan-source)
if [ -n "$CONTAINER_RUNNING" ]; then
    echo "Stopping and removing the existing ckan-source container..."
    docker stop ckan-source || { echo "Failed to stop ckan-source"; exit 1; }
    docker rm ckan-source || { echo "Failed to remove ckan-source"; exit 1; }
fi

# Remove the existing Docker volumes if there are any
CKAN_VOLUME_EXISTS=$(docker volume ls -q -f name=ckan_storage)
if [ -n "$CKAN_VOLUME_EXISTS" ]; then
    echo "Removing the existing ckan_storage volume..."
    docker volume rm ckan_storage || { echo "Failed to remove ckan_storage"; exit 1; }
fi
PG_VOLUME_EXISTS=$(docker volume ls -q -f name=pg_data)
if [ -n "$PG_VOLUME_EXISTS" ]; then
    echo "Removing the existing pg_data volume..."
    docker volume rm pg_data || { echo "Failed to remove pg_data"; exit 1; }
fi


# Build the Docker container
echo "Building the ckan-source container..."
docker build  --build-arg CKAN_VERSION=${CKAN_VERSION} --build-arg XLOADER_VERSION=${XLOADER_VERSION} \
        -t ckan-source . || { echo "Failed to build ckan-source container"; exit 1; }

# Check if the build was successful
echo "ckan-source container built successfully."

# Run the Docker container
echo "Running the ckan-source container..."
docker volume create ckan_storage || { echo "Failed to create ckan-storage volume"; exit 1; }
docker volume create pg_data || { echo "Failed to create pg_storage volume"; exit 1; }
docker run -d -p 8983:8983 -p 5000:5000 --name ckan-source \
                -v ckan_storage:/var/lib/ckan \
                -v ckan_code:/usr/lib/ckan \
                -v pg_data:/var/lib/postgresql \
                ckan-source \
                || { echo "Failed to run ckan-source container"; exit 1; }

# Check if the container is running successfully


echo "ckan-source container is running on port 5000 and solr is running on port 8983."
