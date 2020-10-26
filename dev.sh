# Création de l'image
docker build -f Dockerfile_dev -t img_server_rpi_camalarm:dev .
# Création du container
docker run -tid --restart unless-stopped --device /dev/vchiq --name server_rpi_camalarm-dev -p 8080:8080 -p 8081:8081 -p 8090:8090 img_server_rpi_camalarm:dev