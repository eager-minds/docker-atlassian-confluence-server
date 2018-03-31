FROM openjdk:8-jdk-alpine
MAINTAINER Eager Minds

# Environment vars
ENV CONFLUENCE_HOME      /var/atlassian/application-data/confluence
ENV CONFLUENCE_INSTALL   /opt/atlassian/confluence
ENV CONFLUENCE_VERSION   6.8.0
ENV MYSQL_VERSION 5.1.45
ENV POSTGRES_VERSION 42.2.1

ENV RUN_USER             root
ENV RUN_GROUP            root

ARG DOWNLOAD_URL=http://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz
ARG MYSQL_CONNECTOR_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_VERSION}.tar.gz
ARG MYSQL_CONNECTOR_JAR=mysql-connector-java-${MYSQL_VERSION}/mysql-connector-java-${MYSQL_VERSION}-bin.jar
ARG OLD_POSTGRES_CONNECTOR_JAR=postgresql-42.1.1.jar
ARG POSTGRES_CONNECTOR_DOWNLOAD_URL=https://jdbc.postgresql.org/download/postgresql-${POSTGRES_VERSION}.jar
ARG POSTGRES_CONNECTOR_JAR=postgresql-${POSTGRES_VERSION}.jar

# Print executed commands
RUN set -x

# Install requeriments
RUN apk update -qq
RUN update-ca-certificates
RUN apk add --no-cache    ca-certificates wget curl openssh bash procps openssl perl ttf-dejavu tini libc6-compat

# Confluence set up
RUN rm -rf                /var/lib/{apt,dpkg,cache,log}/ /tmp/* /var/tmp/*
#RUN mkdir -p              ${CONFLUENCE_HOME}
RUN mkdir -p              ${CONFLUENCE_INSTALL}
RUN curl -Ls              ${DOWNLOAD_URL} | tar -xz --strip-components=1 -C "$CONFLUENCE_INSTALL"
RUN ls -la                "${CONFLUENCE_INSTALL}/bin"

# Database connectors
RUN curl -Ls               "${MYSQL_CONNECTOR_DOWNLOAD_URL}"   \
     | tar -xz --directory "${CONFLUENCE_INSTALL}/lib"               \
                           "${MYSQL_CONNECTOR_JAR}"            \
                           --strip-components=1 --no-same-owner
RUN rm -f                  "${CONFLUENCE_INSTALL}/confluence/WEB-INF/lib/${OLD_POSTGRES_CONNECTOR_JAR}"
RUN curl -Ls               "${POSTGRES_CONNECTOR_DOWNLOAD_URL}" -o "${CONFLUENCE_INSTALL}/lib/${POSTGRES_CONNECTOR_JAR}"

# Config
RUN echo -e                "\nconfluence.home=$CONFLUENCE_HOME" >> "${CONFLUENCE_INSTALL}/confluence/WEB-INF/classes/confluence-init.properties"
#RUN sed -i -e             's/-Xms\([0-9]\+[kmg]\) -Xmx\([0-9]\+[kmg]\)/-Xms\${JVM_MINIMUM_MEMORY:=\1} -Xmx\${JVM_MAXIMUM_MEMORY:=\2} \${JVM_SUPPORT_RECOMMENDED_ARGS} -Dconfluence.home=\${CONFLUENCE_HOME}/g' ${CONFLUENCE_INSTALL}/bin/setenv.sh
#RUN sed -i -e             's/port="8090"/port="8090" secure="${catalinaConnectorSecure}" scheme="${catalinaConnectorScheme}" proxyName="${catalinaConnectorProxyName}" proxyPort="${catalinaConnectorProxyPort}"/' ${CONFLUENCE_INSTALL}/conf/server.xml


USER root:root

# Expose HTTP and Synchrony ports
EXPOSE 8090
EXPOSE 8091

VOLUME ["/var/atlassian/application-data/confluence", "/opt/atlassian/confluence/logs"]

WORKDIR $CONFLUENCE_HOME

COPY . /tmp
COPY "entrypoint.sh" "/"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh", "-fg"]
