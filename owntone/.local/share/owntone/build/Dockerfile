ARG PACKAGE_REPOSITORY_URL=https://dl-cdn.alpinelinux.org/alpine/v3.21

FROM alpine:3.21 AS build

ARG DISABLE_UI_BUILD
ARG PACKAGE_REPOSITORY_URL
ARG REPOSITORY_URL=https://github.com/owntone/owntone-server.git
ARG REPOSITORY_VERSION=29.0

WORKDIR /tmp/source

RUN \
  apk add -U -q --no-cache --no-progress --repository ${PACKAGE_REPOSITORY_URL} \
    alsa-lib-dev \
    autoconf \
    automake \
    avahi-dev \
    bison \
    confuse-dev \
    curl-dev \
    ffmpeg-dev \
    flex \
    g++ \
    gawk \
    gcc \
    gettext-dev \
    git \
    gnutls-dev \
    gperf \
    json-c-dev \
    libevent-dev \
    libgcrypt-dev \
    libplist-dev \
    libsodium-dev \
    libtool \
    libunistring-dev \
    libwebsockets-dev \
    libxml2-dev \
    make \
    npm \
    protobuf-c-dev \
    pulseaudio-dev \
    sqlite-dev && \
  git clone ${REPOSITORY_URL} ./ && \
  git checkout tags/${REPOSITORY_VERSION} && \
  if [ -z ${DISABLE_UI_BUILD} ]; then cd web-src; npm install; npm run build; cd ..; fi && \
  autoreconf -fvi -I /usr/share/gettext/m4 && \
  ./configure \
    --disable-install_systemd \
    --disable-install_user \
    --enable-chromecast \
    --enable-silent-rules \
    --with-pulseaudio \
    --infodir=/usr/share/info \
    --localstatedir=/var \
    --mandir=/usr/share/man \
    --prefix=/usr \
    --sysconfdir=/etc/owntone && \
  make DESTDIR=/tmp/build install && \
  cd /tmp/build && \
  install -D etc/owntone/owntone.conf usr/share/doc/owntone/examples/owntone.conf && \
  rm -rf var etc

FROM alpine:3.21 AS runtime

ARG PACKAGE_REPOSITORY_URL

COPY --from=build /tmp/build/ .
COPY etc/init.d/owntone /etc/init.d/owntone

RUN \
  apk add -U -q --no-cache --no-progress --repository ${PACKAGE_REPOSITORY_URL} \
    avahi \
    busybox-openrc \
    confuse \
    curl \
    dbus \
    ffmpeg \
    gnutls \
    json-c \
    libevent \
    libgcrypt \
    libplist \
    libsodium \
    libunistring \
    libuuid \
    libwebsockets \
    libxml2 \
    openrc \
    protobuf-c \
    pulseaudio \
    shadow \
    sqlite \
    sqlite-libs \
    udev-init-scripts-openrc && \
  rm /etc/avahi/services/* && \
  sed -i 's/^\(tty\d\:\:\)/#\1/g' /etc/inittab && \
  sed -i \
    -e 's/#rc_env_allow=".*"/rc_env_allow="UID GID"/g' \
    -e 's/#rc_provide=".*"/rc_provide="loopback net"/g' \
    -e 's/#rc_sys=".*"/rc_sys="docker"/g' \
    /etc/rc.conf && \
  rc-update add syslog boot && \
  rc-update add owntone default && \
  install -D /dev/null /run/openrc/softlevel

ENTRYPOINT ["/sbin/init"]

HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=3 \
  CMD ["/sbin/rc-service", "owntone", "status"]
