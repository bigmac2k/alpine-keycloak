FROM alpine as base

RUN addgroup -g 1000 jboss && adduser -S -h /opt/jboss -s /sbin/nologin -g jboss -u 1000 jboss
RUN apk add --no-cache bash openjdk11 openssl which
WORKDIR /opt/jboss

ENV LAUNCH_JBOSS_IN_BACKGROUND 1
ENV PROXY_ADDRESS_FORWARDING false
ENV JBOSS_HOME /opt/jboss/keycloak
ENV LANG en_US.UTF-8

FROM base as build

ENV KEYCLOAK_VERSION 8.0.1
ENV JDBC_POSTGRES_VERSION 42.2.5
ENV JDBC_MYSQL_VERSION 5.1.46
ENV JDBC_MARIADB_VERSION 2.2.3
ENV JDBC_MSSQL_VERSION 7.4.1.jre8

RUN apk add --no-cache curl git maven gzip tar

ARG GIT_REPO
ARG GIT_BRANCH
ARG KEYCLOAK_DIST=https://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz
ARG TOOLS_BRANCH=8.0.1
ARG WEBAUTHN_BRANCH=612c6bcdb0cc1a1da87703a97195a2541d257eff

ADD hostname.patch ./
RUN git clone https://github.com/keycloak/keycloak-containers.git && cd keycloak-containers && git checkout ${TOOLS_BRANCH} && git apply < ../hostname.patch && cd .. && rm hostname.patch && mv keycloak-containers/server/tools . && rm -rf keycloak-containers
RUN /opt/jboss/tools/build-keycloak.sh
RUN mkdir /build && cd /build && git clone https://github.com/webauthn4j/keycloak-webauthn-authenticator.git . && git checkout ${WEBAUTHN_BRANCH}
WORKDIR /build
RUN mvn install -Dmaven.test.skip -DskipTests

FROM base
COPY --from=build /opt/jboss /opt/jboss
COPY --from=build /build/webauthn4j-ear/target/keycloak-webauthn4j-ear-*.ear /opt/jboss/keycloak/standalone/deployments/
RUN chown -R jboss:jboss /opt/jboss

USER 1000

EXPOSE 8080
EXPOSE 8443

ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh" ]

CMD ["-b", "0.0.0.0"]
