CKAN and all services running in one Docker Container


* [1. Overview](#1-overview)
* [2. Building and Running the Docker Container](#2-building-and-running-the-docker-container)



## 1.  Overview

This is designed as a replacement to using a Virtual Machine (or physical machine) to install a CKAN environment. I personally used to use [VirtualBox](https://www.virtualbox.org) to run 
Ubuntu Virtual Machines on my Mac OS host but Iv'e been experiencing more and more problems in getting these VM's running. This is a replacement environment for products like VitualBox and VMWare.
The idea here is to use Docker only yo provide a basic Ubuntu machine to install the software

For this repo the following versions were used:

* Ubuntu      **22.04**
* CKAN        **2.11.1**
* Python      **3.10**
* PostgreSQL  **14**
* Solr        **9.7.0**
* JRE         **11**

There is no reason why other versions could be used. It should be very straightforward to replace any of these versions with another

## 2.  Building and Running the Docker Container

There are 3 files in this repo:

1. doit.sh
2. Dockerfile
3. start_all_processes.sh

### 1. doit.sh
This is the script that runs the docker build and starts the docker container
This script automates:

* Cleaning up existing containers
* Building a CKAN Docker image
* Creating persistent storage volumes
* Running the CKAN container with specific configurations

### 2. Dockerfile
This Dockerfile is for setting up a CKAN environment with several key components. 

#### Base Image and Environment:
* Uses Ubuntu 22.04 as the base image
* Sets up environment variables for specific CKAN and XLoader versions
* Prevents interactive prompts during installation


#### System Dependencies:
* Installs various system packages including:
* Python development tools
* Git
* Redis server
* Network utilities
* PostgreSQL
* OpenJDK 11

#### Python Virtual Environment:
* Creates a Python 3.10 virtual environment at `/usr/lib/ckan/default`
* Upgrades pip
* Installs CKAN directly from its GitHub repository
* Installs CKAN XLoader extension

#### Database and Search Components:
* Installs PostgreSQL for database functionality
* Installs Solr (version 9.7.0) for search capabilities
* Creates a dedicated solr user and group
* Sets up Solr home directory and Java environment


#### Additional Configuration:
* Copies a start_all_processes.sh script to manage startup
* Exposes multiple ports (5000, 6379, 5432, 8983, 8800) for various services
* Uses the startup script as the default CMD

The Dockerfile is designed to create a comprehensive CKAN installation with all necessary dependencies, ready to be deployed as a containerized application for data management and publishing.

### 3. start_all_processes.sh

#### Database Setup:
* Starts PostgreSQL service
* Creates a CKAN database user (ckan_default)
* Creates a ckan_default database
* Grants all privileges to the database user

#### CKAN Configuration:
* Activates the Python virtual environment
* Generates the CKAN configuration file (ckan.ini)
* Sets appropriate permissions on the configuration directory

#### Solr Search Configuration:
* Starts Solr service
* Creates a CKAN Solr core
* Downloads the CKAN schema for Solr
* Restarts Solr to apply configurations

#### Redis Setup:
* Starts the Redis server for caching and background job management

#### Database Initialization:
* Initializes CKAN database tables
* Waits briefly to ensure Solr is loaded

#### Admin User Creation:
* Creates a CKAN admin user (ckan_admin)
* Sets the admin user as a system administrator

#### Datastore Extension Configuration:
* Configures datastore write and read URLs in the CKAN configuration
* Creates a datastore database and user
* Sets datastore permissions

#### XLoader and Plugins Configuration:
* Generates an API token for the admin user
* Configures CKAN plugins (including XLoader, datastore, and view plugins)
* Starts the background jobs worker

#### CKAN Server Startup:
* Starts the CKAN server, listening on all interfaces (0.0.0.0) on port 5000
* Includes a final infinite loop to keep the container running

The script is typically used as an entrypoint for a Docker container, automating the entire setup and startup process for a CKAN instance with various extensions and services pre-configured.

