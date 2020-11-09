FROM alpine:3.12.1 as base

RUN addgroup -g 1000 jboss && adduser -S -h /opt/jboss -s /sbin/nologin -g jboss -u 1000 jboss
RUN apk add --no-cache bash openjdk11-jre-headless openssl which
WORKDIR /opt/jboss

ENV LAUNCH_JBOSS_IN_BACKGROUND 1
ENV PROXY_ADDRESS_FORWARDING false
ENV JBOSS_HOME /opt/jboss/keycloak
ENV LANG en_US.UTF-8

FROM base as build

RUN apk add --no-cache git curl

ENV KEYCLOAK_VERSION 11.0.3
ENV JDBC_POSTGRES_VERSION 42.2.5
ENV JDBC_MYSQL_VERSION 8.0.19
ENV JDBC_MARIADB_VERSION 2.5.4
ENV JDBC_MSSQL_VERSION 7.4.1.jre11

ARG GIT_REPO
ARG GIT_BRANCH
ARG KEYCLOAK_DIST=https://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz

USER root

RUN apk add --no-cache

ADD tools /opt/jboss/tools
RUN /opt/jboss/tools/build-keycloak.sh

FROM base
COPY --from=build /opt/jboss /opt/jboss

USER 1000

EXPOSE 8080
EXPOSE 8443

ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh" ]

CMD ["-b", "0.0.0.0"]
