FROM ubuntu:22.04

# Prevent interactive prompts during installation

ARG CKAN_VERSION
ARG XLOADER_VERSION
ENV CKAN_TAG="ckan-${CKAN_VERSION}"
ENV XLOADER_VERSION=${XLOADER_VERSION}
ENV CKAN_GIT_URL=https://github.com/ckan/ckan.git
ENV XLOADER_GIT_URL https://github.com/ckan/ckanext-xloader.git
ENV DEBIAN_FRONTEND=noninteractive

# Set the working directory
WORKDIR /srv/app

# Install libraries and software
RUN apt-get update && apt-get install -y \
    systemd \
    net-tools \
    python3-dev \
    python3-pip \
    python3-venv \
    libpq-dev \
    git-core \
    redis-server \
    libmagic1 \
    vim \
    curl \
    wget \
    git \
    sudo \
    lsof \
    && apt-get clean

# Set the working directory
WORKDIR /srv/app

RUN sudo mkdir -p /usr/lib/ckan/default && \
    sudo chown `whoami` /usr/lib/ckan/default && \
    python3.10 -m venv /usr/lib/ckan/default

RUN pip install --upgrade pip

# Install CKAN
RUN . /usr/lib/ckan/default/bin/activate && \
    cd /usr/lib/ckan/default && \
    pip install -e git+${CKAN_GIT_URL}@${CKAN_TAG}#egg=ckan && \
    cd src/ckan/ && \
    pip install --no-binary markdown -r requirements.txt

# Install CKAN extensions
# - CKAN XLoader
RUN . /usr/lib/ckan/default/bin/activate && \
    cd /usr/lib/ckan/default/src && \
    pip install -e git+${XLOADER_GIT_URL}@master#egg=ckanext-xloader && \
    cd ckanext-xloader && \
    pip install -r requirements.txt && \
    pip install -U requests[security]

# PostgreSQL stuff now
RUN apt-get update && \
    apt-get install -y \
    postgresql \
    postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

# SOLR stuff now
RUN apt-get update && \
    apt-get install -y \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*
    
ENV SOLR_VERSION=9.7.0 \
    SOLR_HOME=/opt/solr \
    SOLR_USER=solr \
    SOLR_GROUP=solr \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Create a solr user and group
RUN groupadd -r $SOLR_GROUP && useradd -r -g $SOLR_GROUP $SOLR_USER

# Download Solr
RUN wget -O solr-$SOLR_VERSION.tgz https://www.apache.org/dyn/closer.lua/solr/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz?action=download && \
    tar xzf solr-$SOLR_VERSION.tgz && \
    mv solr-$SOLR_VERSION /opt/solr && \
    rm solr-$SOLR_VERSION.tgz

# Set permissions
RUN mkdir -p /opt/solr && chown -R $SOLR_USER:$SOLR_GROUP /opt/solr

COPY start_all_processes.sh /srv/app/start_all_processes.sh
RUN chmod +x /srv/app/start_all_processes.sh 

# Expose the ports
EXPOSE 5000 6379 5432 8983 8800

CMD ["/srv/app/start_all_processes.sh"]