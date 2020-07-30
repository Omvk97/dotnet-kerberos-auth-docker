# dotnet-kerberos-auth-docker

This image serves as a base image (debian) for applications which uses [confluent-kafka-dotnet](https://github.com/confluentinc/confluent-kafka-dotnet) and requires kerberos authentication.

TODO: Use this other image if you use Golang
TODO: Use this other image if you use python

# Guide

1. Base your image on omvk97/dotnet-kerberos-auth
2. Build your application for release and put it in a directory of your choice
3. Set the environment variable `DOTNET_PROGRAM_HOME` to the directory where your built code is.
4. Make sure to run `replace-librdkafka.sh` inside the container before you start your container.
5. Make sure to run `configure-krb5.sh` inside the container before you start your container. This script requires two arguments. The first being the Kerberos Realm, the second being the url of the kerberos server.
6. We recommend to place your keytab in the location provided with the environment variable called 'KEYTAB_LOCATION' (`/sasl/program.service.keytab`). This environment variable can then be used in your dotnet code to point to the keytab that confluent-kafka-dotnet should use.

## Dockerfile example

```
# ---- dotnet build stage ----
FROM mcr.microsoft.com/dotnet/core/sdk:3.1 as build

ARG BUILDCONFIG=RELEASE
ARG VERSION=1.0.0

WORKDIR /build/

COPY ./Example.csproj ./Example.csproj
RUN dotnet restore ./Example.csproj

COPY ./Example ./

RUN dotnet build -c ${BUILDCONFIG} -o out && dotnet publish ./Example.csproj -c ${BUILDCONFIG} -o out /p:Version=${VERSION}

# ---- final stage ----

FROM omvk97/dotnet-kerberos-auth

ENV DOTNET_PROGRAM_HOME=/opt/Example

COPY --from=build /build/out ${DOTNET_PROGRAM_HOME}

# Copy necessary scripts + configuration
COPY scripts /tmp/
RUN chmod +x /tmp/*.sh && \
    mv /tmp/* /usr/bin && \
    rm -rf /tmp/*

CMD [ "docker-entrypoint.sh" ]
```

Where 'docker-entrypoint.sh' runs the script 'replace-librdkafka.sh'

```
#!/bin/bash

set -eo pipefail

# replace-librdkafka.sh is run here
replace-librdkafka.sh

# other configuration is done in this script
check-environment.sh

# the application is started
dotnet "$DOTNET_PROGRAM_HOME"/Example.dll
```

Where check-environment.sh runs the script 'configure-krb5.sh'

```
# configuring krb5.conf files so acl-manager can communicate with kerberos server and ensure the provided keytab is correct
configure-krb5.sh "$KERBEROS_REALM" "$KERBEROS_PUBLIC_URL"
```