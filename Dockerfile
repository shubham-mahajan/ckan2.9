# See CKAN docs on installation from Docker Compose on usage
FROM debian:stretch
MAINTAINER Open Knowledge

# Install required system packages
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
        python-dev \
        python-pip \
        python-virtualenv \
        python-wheel \
        python3-dev \
        python3-pip \
        python3-virtualenv \
        python3-wheel \
        libpq-dev \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        postgresql-client \
        build-essential \
        git-core \
        vim \
        wget \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/venv
ENV CKAN_CONFIG /etc/ckan
# ENV CKAN_STORAGE_PATH=/var/lib/ckan
ENV CKAN_EXTENSIONS $CKAN_HOME/src_extensions

# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Create ckan user
RUN useradd -r -u 900 -m -c "ckan account" -d $CKAN_HOME -s /bin/false ckan

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH $CKAN_EXTENSIONS && \
    virtualenv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip /usr/local/bin/ckan-pip &&\
    ln -s $CKAN_VENV/bin/ckan /usr/local/bin/ckan

#ENV CKAN__PLUGINS envvars stats text_view image_view recline_view geoview

# Setup CKAN
ADD . $CKAN_VENV/src/ckan/
RUN cp -r /usr/lib/ckan/venv/src/ckan/extensions/* $CKAN_EXTENSIONS/ 
RUN ckan-pip install -U pip && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirement-setuptools.txt && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirements-py2.txt && \
    ckan-pip install -e $CKAN_VENV/src/ckan/ && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/start_ckan.sh /start_ckan.sh && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/build_extensions.sh /build_extensions.sh && \
    # cp -r $CKAN_HOME/src/extensions/ $CKAN_EXTENSIONS/ && \
    chmod +x /start_ckan.sh && \
    chown -R ckan:ckan /start_ckan.sh && \
    chmod +x /build_extensions.sh && \
    chown -R ckan:ckan /build_extensions.sh

RUN ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/ckan-entrypoint.sh /ckan-entrypoint.sh && \
    chmod +x /ckan-entrypoint.sh && \
    chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH $CKAN_EXTENSIONS

RUN ckan-pip install -e git+https://github.com/ckan/ckanext-geoview@v0.0.12#egg=ckanext-geoview
    
ENV CKAN__PLUGINS envvars stats text_view image_view recline_view datastore datapusher geo_view linechart barchart piechart basicgrid

RUN ["/build_extensions.sh"]
#ENTRYPOINT ["/ckan-entrypoint.sh"]
USER ckan
RUN ckan generate config ${CKAN_CONFIG}/production.ini && \
    ckan config-tool /etc/ckan/production.ini "ckan.plugins = ${CKAN__PLUGINS}" && \
    ckan config-tool /etc/ckan/production.ini "ckan.site_url = ${CKAN__SITE_URL}"



ENTRYPOINT ["/ckan-entrypoint.sh"]
# ENTRYPOINT ["/start_ckan.sh"]

EXPOSE 5000
CMD ["/start_ckan.sh"]