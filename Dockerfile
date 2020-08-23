FROM arm32v6/alpine:3.11
LABEL maintainer="julien"

# Crée un utilisateur sans mot de passe, sans créer le /home avec un shell sur /bin/false
# Utilisateur déjà créé lors de l'installation de nginx
RUN apk update && \
    apk add --no-cache luarocks5.1 nginx nginx-mod-http-lua lua5.1-socket git make gcc musl-dev raspberrypi && \
    git clone https://github.com/ccrisan/streameye.git && cd streameye && make && make install && cd .. && rm -rf streameye && \
    luarocks-5.1 install lua-resty-core && \
    apk del git make gcc musl-dev luarocks5.1 && \
    rm /var/cache/apk/*

RUN adduser -H -D -g 'www' -G tty -s /bin/false www

# Se placer dans le répertoire /app
WORKDIR /app
# On crée le répertoire /app/cfg et /app/run
RUN mkdir /app/cfg /app/run && \
    # Supprime la configuration de nginx par défaut
    rm /etc/nginx/nginx.conf && rm /etc/nginx/conf.d/default.conf

# Ajout de ma configuration personnel
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/conf.d/camalarm.conf /etc/nginx/conf.d/camalarm.conf

# Ajout du programme lua pour gérer l'API REST
COPY *.lua /app/
# Ajout de la configuration placée avec l'application
COPY ./cfg/camalarm.toml /app/cfg

# On rend /opt/vc accessible depuis le container pour avoir les lib nécessaire à raspistill et raspivid
VOLUME /opt/vc:/opt/vc

# Par défaut, linux n'utilise pas ces répertoires donc il faut passer une variable d'environnement
ENV LD_LIBRARY_PATH=/opt/vc/lib
# On redéfinit le PATH
ENV PATH="$PATH:/opt/vc/bin"

# Mettre les bonnes permissions
RUN chown -R www: /app && chmod -R 744 /app && \
    mkdir /run/nginx && touch /run/nginx/nginx.pid && \
    chown -R www: /run/nginx && \
    chown -R www: /var/lib/nginx && \
    chown -R www: /var/log/nginx && \
    chown -R www: /etc/nginx/nginx.conf && \
    chown -R www: /etc/nginx/conf.d/

# On rend accessible les ports 8080, 8081 et 8090. 8090 c'est pour accéder à l'API, 8080 et 8081 pour accéder au stream. 8080 stream alarm et 8081 stream pur
EXPOSE 8080 8081 8090

# Passage sous l'utilisateur nginx correspondant à un su nginx
USER www

# Pour lancer nginx (en utilisateur normal)
ENTRYPOINT ["nginx"]
