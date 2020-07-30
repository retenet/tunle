ARG ARCH

FROM ${ARCH}/alpine:3.12

ARG BUILD_DATE
ARG VERSION
ARG VCS_URL
ARG VCS_REF

LABEL maintainer="Craig West <dev@exploit.design>" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="tunle" \
      org.label-schema.description="Dockerized Tunneling" \
      org.label-schema.url="https://tunle.io" \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" 

RUN \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk add -q --no-progress --no-cache --update \
    bash \
    ca-certificates \
    curl \
    i2pd \
    iptables \
    ip6tables \
    jq \
    openvpn \
    tini \
    tor \
    tzdata \
    unzip && \
  rm -fr /var/cache/apk/* && \
  adduser -D -h /home/user -u 9001 user

WORKDIR /app

COPY . .

HEALTHCHECK --interval=5m --timeout=5s \
  CMD curl -fL one.one.one.one || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/bash", "setup.sh"]
