FROM ubuntu:20.04 as build

RUN apt-get update && apt-get install -y mono-devel default-jre build-essential libssl-dev libsasl2-2 libsasl2-dev libsasl2-modules-gssapi-mit unzip

# lib folder contains librdkafka zip
COPY ./lib/ ./
# installing librdkafka manually
RUN unzip librdkafka-1.5.0.zip && \
    cd librdkafka-1.5.0 && \
    ./configure && \
    make && \
    make install

FROM ubuntu:20.04

LABEL Maintainer="Oliver Marco van Komen"

ENV ASPNETCORE_ENVIRONMENT=Production
ENV CONF_FILES=/conf

# installing aspnet core runtime for ubuntu
RUN apt-get update && \
    apt-get install -y wget && wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg --purge packages-microsoft-prod && dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install aspnetcore-runtime-3.1 curl vim -y && \
    rm packages-microsoft-prod.deb 

# Kafka SASL directory (keytab is placed here) and conf files (krb5.conf is placed here for krb5-user)
RUN mkdir /sasl/ && mkdir ${CONF_FILES} && mkdir librdkafka
COPY ./configuration/ ${CONF_FILES}/

# This is where the user should place their keytab
ENV KEYTAB_LOCATION=/sasl/program.service.keytab

# Installing dependencies for librdkafka
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install krb5-user \
    libsasl2-2 libsasl2-modules-gssapi-mit libsasl2-modules \
    && apt-get autoremove

COPY --from=build /usr/local/lib/librdkafka*.so* librdkafka/

# Copy necessary scripts + configuration
COPY scripts /tmp/
RUN chmod +x /tmp/*.sh && \
    mv /tmp/* /usr/bin && \
    rm -rf /tmp/*

