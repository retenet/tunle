ARG ARCH

FROM ${ARCH}/golang:1.15.5-alpine3.12 as builder

ARG wg_go_tag=v0.0.20201118
ARG wg_tools_tag=v1.0.20200827

RUN apk add --update git build-base libmnl-dev iptables

RUN git clone https://git.zx2c4.com/wireguard-go && \
    cd wireguard-go && \
    git checkout $wg_go_tag && \
    make && \
    make install

ENV WITH_WGQUICK=yes
RUN git clone https://git.zx2c4.com/wireguard-tools && \
    cd wireguard-tools && \
    git checkout $wg_tools_tag && \
    cd src && \
    make && \
    make install

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
    iproute2 \
    iptables \
    ip6tables \
    jq \
    libmnl \
    openresolv \
    openvpn \
    tini \
    tor \
    tzdata \
    unzip && \
  rm -fr /var/cache/apk/* && \
  adduser -D -h /home/user -u 9001 user

WORKDIR /app

COPY --from=builder /usr/bin/wireguard-go /usr/bin/wg* /usr/bin/
COPY . .

HEALTHCHECK --interval=5m --timeout=5s \
  CMD curl -fL html.duckduckgo.com || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/bash", "setup.sh"]
