# Utilisation de l'image de base construite précédemment
FROM ghcr.io/laveracloudsolutions/php-runner:8.5-apache-trixie

ENV COMPOSER_VERSION=2.2.25
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV APACHE_DOCUMENT_ROOT=/var/www/html/api/public

# 1. Configuration du dépôt NodeSource (Node 20)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# 2. Configuration du dépôt Yarn (Méthode moderne sans apt-key)
RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# 3. Mise à jour et installation des packages (Versions adaptées à Trixie)
RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install -qy \
    bind9 \
    git \
    glibc-source \
    gnutls-bin \
    libkrb5-3 \
    libtasn1-6 \
    nodejs \
    yarn \
    zsh

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 4. Installation de Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}

# 5. Installation des extensions PECL (Xdebug & PCOV)
RUN pecl install xdebug pcov && \
    docker-php-ext-enable xdebug pcov

# 6. Configuration Apache
RUN a2enmod rewrite remoteip headers security2

# 7. Outillage global
RUN npm install -g commitizen

# 8. Installation de Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash && \
    apt-get install -y symfony-cli

# Copies des configurations locales
COPY ./config/apache/000-default.conf /etc/apache2/sites-available/
COPY ./config/php/php.ini $PHP_INI_DIR/php.ini
COPY ./config/php/php-cli.ini $PHP_INI_DIR/php-cli.ini
COPY ./config/php/xdebug.ini $PHP_INI_DIR/conf.d/xxx-xdebug.ini

WORKDIR /var/www/html