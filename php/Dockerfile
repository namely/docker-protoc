FROM namely/protoc
MAINTAINER Core Services <coreservices@namely.com>

RUN apk --update add wget \ 
  curl \
  git \
  grep \
  gmp-dev \
  libmcrypt-dev \
  freetype-dev \
  libxpm-dev \
  libwebp-dev \
  libjpeg-turbo-dev \
  libjpeg \
  bzip2-dev \
  openssl \
  openssl-dev \
  krb5-dev \
  libxml2-dev \
  build-base \
  tar \
  make \
  autoconf

RUN apk --update add re2c bison curl-dev openssl

RUN apk --update add php5 php5-fpm php5-dev php5-phar php5-json php5-openssl --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/

RUN rm /var/cache/apk/*

COPY ./php.ini /etc/php5/conf.d/custom.ini

RUN git clone https://github.com/chobie/php-protocolbuffers.git && cd php-protocolbuffers && \
	/usr/bin/phpize && \ 
	./configure --with-php-config=/usr/bin/php-config && \
	make && \
  make install

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer 

COPY composer.json /root/.composer/composer.json

RUN composer global install

RUN export PATH=/root/.composer/vendor/protocolbuffers/protoc-gen-php/bin/:$PATH

COPY script.sh /opt/namely/script.sh
ENTRYPOINT ["/opt/namely/script.sh"]
