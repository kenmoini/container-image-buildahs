#!/bin/bash -ex

NAME=base-nginx-packages
NGINX_VERSION=1.14.2
NGINX_SHORT_VER=114

container=$(buildah from registry.gitlab.fiercesw.network/kemo-org/container-image-repo/base-fedora-29)
mountpath=$(buildah mount $container)

trap "set +ex; buildah umount $container; buildah delete $container" EXIT

# Tag the image
buildah config --label maintainer="Ken Moini <ken@kenmoini.com>" $container
buildah config --created-by "Ken Moini" $container
buildah config --author "ken@kenmoini.com" $container
buildah config --workingdir /tmp $container
buildah config --port 8080/tcp $container
buildah config --port 8443/tcp $container

# Install updates
#buildah run $container dnf upgrade -y && dnf clean all

# Install needed packages
buildah run $container dnf install -y curl wget gzip tar zip unzip gettext git tree perl perl-devel perl-ExtUtils-Embed libxslt libxslt-devel libxml2 libxml2-devel gd gd-devel GeoIP GeoIP-devel gcc-c++ libatomic_ops libatomic_ops-devel supervisor
buildah run $container dnf groupinstall -y 'Development Tools'
buildah run $container dnf clean all

# Pull in NGINX and needed packages
buildah run $container wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
buildah run $container tar zxf nginx-$NGINX_VERSION.tar.gz
buildah run $container wget https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.gz
buildah run $container tar zxf pcre-8.42.tar.gz
buildah run $container wget https://zlib.net/zlib-1.2.11.tar.gz
buildah run $container tar zxf zlib-1.2.11.tar.gz
buildah run $container wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz 
buildah run $container tar zxf openssl-1.1.1b.tar.gz
buildah run $container rm -rf *.tar.gz

buildah config --workingdir /tmp/nginx-$NGINX_VERSION $container

buildah run $container ./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --user=nginx \
  --group=nginx \
  --with-http_degradation_module \
  --with-http_ssl_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_stub_status_module \
  --with-http_auth_request_module \
  --with-http_xslt_module=dynamic \
  --with-http_image_filter_module=dynamic \
  --with-http_geoip_module=dynamic \
  --with-http_perl_module=dynamic \
  --with-threads \
  --with-select_module \
  --with-poll_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-stream_realip_module \
  --with-stream_geoip_module=dynamic \
  --with-http_slice_module \
  --with-mail \
  --with-mail_ssl_module \
  --with-compat \
  --with-file-aio \
  --with-http_v2_module \
  --with-pcre=../pcre-8.42 \
  --with-pcre-jit \
  --with-zlib=../zlib-1.2.11 \
  --with-openssl=../openssl-1.1.1b \
  --with-openssl-opt=no-nextprotoneg \
  --with-debug

buildah run $container make -j$(getconf _NPROCESSORS_ONLN)
buildah run $container make install

# Add system user
buildah run $container useradd --system --home /var/cache/nginx --shell /sbin/nologin --comment "nginx user" --user-group nginx

# Configure a few things
buildah run $container mkdir -p /etc/nginx/{conf.d,ssl,sites-available,sites-enabled}
buildah run $container mkdir -p /var/www/html
buildah run $container mkdir -p /var/cache/nginx/{client_temp,fastcgi_temp,uwsgi_temp,scgi_temp}
buildah run $container ln -s /usr/lib/nginx/modules /etc/nginx/modules
# Just reroute to stderr via nginx conf
#buildah run $container ln -sf /dev/stdout /var/log/nginx/access.log
#buildah run $container ln -sf /dev/stderr /var/log/nginx/error.log

# Copy config over
buildah copy $container ./conf/nginx.conf /etc/nginx/nginx.conf
buildah copy $container ./conf/default-site /etc/nginx/sites-available/default
buildah copy $container ./conf/supervisord.conf /etc/supervisord.conf
buildah copy $container ./scripts/start.sh /start.sh
buildah copy $container ./scripts/push /usr/bin/push
buildah copy $container ./scripts/pull /usr/bin/pull
buildah copy $container ./src/ /var/www/html/
buildah run $container chmod 755 /usr/bin/pull
buildah run $container chmod 755 /usr/bin/push
buildah run $container chmod 755 /start.sh
buildah run $container ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

buildah config --workingdir /tmp/ $container
buildah run $container rm -rf pcre*
buildah run $container rm -rf nginx*
buildah run $container rm -rf zlib*
buildah run $container rm -rf openssl*

# Remove local copies
rm -rf .kemo-buildah-tmp

buildah config --workingdir /var/www/html/ $container
buildah config --entrypoint /start.sh $container

buildah commit --format docker $container base-nginx-fedora-29:latest
