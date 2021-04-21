# See CKAN docs on installation from Docker Compose on usage
FROM alpine:3.13 as ckanbuild

# Install required system packages
RUN apk add git \
        curl \
        python3 \
        postgresql-dev \
        linux-headers \
        gcc \
        make \
        g++ \
        autoconf \
        automake \
        libtool \
        patch \
        musl-dev \
        pcre-dev \
        pcre \
        python3-dev \
        libffi-dev \
        libxml2-dev \
        libxslt-dev

# Install necessary packages to run CKAN
RUN apk add git \
        bash \
        gettext \
        curl \
        postgresql-client \
        python3 \
        libmagic \
        pcre \
        libxslt \
        libxml2 \
        tzdata \
        apache2-utils && \
    # Link python to python3
    ln -s /usr/bin/python3 /usr/bin/python

# Install PIP and setup tools
RUN curl -o ${SRC_DIR}/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python ${SRC_DIR}/get-pip.py && \
    pip install setuptools==44.1.0

# Define environment variables
ENV CKAN_HOME /srv/app
ENV CKAN_VENV $CKAN_HOME/venv
ENV CKAN_CONFIG /srv/app
ENV CKAN_STORAGE_PATH=/var/lib/ckan
ENV CKAN_EXTENSIONS $CKAN_HOME/src_extensions

ARG CKAN_SITE_URL

# Create ckan user
RUN addgroup -g 92 -S ckan && \
    adduser -u 92 -h /srv/app -H -D -S -G ckan ckan

# Install Virtual Env
RUN pip install virtualenv

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH $CKAN_EXTENSIONS && \
    virtualenv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip /usr/local/bin/ckan-pip &&\
    ln -s $CKAN_VENV/bin/ckan /usr/local/bin/ckan

# Setup CKAN
ADD . $CKAN_VENV/src/ckan/
RUN cp -r /srv/app/venv/src/ckan/extensions/* $CKAN_EXTENSIONS/ 
RUN ckan-pip install -U pip && \
    ckan-pip install --upgrade -r $CKAN_VENV/src/ckan/requirement-setuptools.txt && \
    ckan-pip install --upgrade -r $CKAN_VENV/src/ckan/requirements.txt && \
    ckan-pip install -e $CKAN_VENV/src/ckan/ && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/start_ckan.sh /start_ckan.sh && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/build_extensions.sh /build_extensions.sh && \
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

USER ckan
RUN ckan generate config ${CKAN_CONFIG}/production.ini && \
    ckan config-tool ${CKAN_CONFIG}/production.ini "ckan.plugins = ${CKAN__PLUGINS}" && \
    ckan config-tool ${CKAN_CONFIG}/production.ini "ckan.site_url = ${CKAN__SITE_URL}"

ENTRYPOINT ["/ckan-entrypoint.sh"]
EXPOSE 5000
CMD ["/start_ckan.sh"]