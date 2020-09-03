# Création de l'image
docker build -t img_alpine_rpi_camalarm:v1.0.2 .
# Création du container
docker run -d --restart unless-stopped --device /dev/vchiq --name server_alpine_rpi_camalarm-v1.0.2 -p 8080:8080 -p 8081:8081 -p 8090:8090 img_alpine_rpi_camalarm:v1.0.2