#!/bin/bash

FLOWSTACK_DIR="/usr/local/flowstack"

# ตรวจสอบและสร้างโฟลเดอร์ flowstack ถ้ายังไม่มี
if [ ! -d "$FLOWSTACK_DIR" ]; then
    mkdir -p "$FLOWSTACK_DIR"
    echo "สร้างโฟลเดอร์ $FLOWSTACK_DIR สำเร็จ!"
else
    echo "โฟลเดอร์ $FLOWSTACK_DIR มีอยู่แล้ว"
fi

# ตรวจสอบและสร้างไฟล์ docker-compose.yml ถ้ายังไม่มี
DOCKER_COMPOSE_FILE="$FLOWSTACK_DIR/docker-compose.yml"
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    cat <<EOF > "$DOCKER_COMPOSE_FILE"
services:
  flowstack:
    image: harbor.nexpie.com/flowstack/flowstack:2.0-25-0cb78b1e
    restart: always
    privileged: true
    ports:
      - "\${FLOWSTACK_PUBLIC_PORT}:80"
    volumes:
      - flowstack-volume:/app/volume
      - flowstack-profile:/app/profile
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - FLOWSTACK_DEPLOYMENT_MODE=\${FLOWSTACK_DEPLOYMENT_MODE}
      - FLOWSTACK_PLATFORM_VERSION=\${FLOWSTACK_PLATFORM_VERSION}
      - FLOWSTACK_STREAM_CATALOGUE=\${FLOWSTACK_STREAM_CATALOGUE}
      - FLOWSTACK_OAUTH_LOGIN=true
      - FLOWSTACK_PASSWORD_LOGIN=true
      - FLOWSTACK_ADMINISTRATOR_PASSWORD=\${FLOWSTACK_ADMINISTRATOR_PASSWORD}
      - FLOWSTACK_APP_MENU_GRAFANA_URI=\${FLOWSTACK_APP_MENU_GRAFANA_URI}
      - FLOWSTACK_APP_MENU_NOTEBOOK_URI=\${FLOWSTACK_APP_MENU_NOTEBOOK_URI}
      - FLOWSTACK_APP_MENU_SCADA_URI=\${FLOWSTACK_APP_MENU_SCADA_URI}
      - FLOWSTACK_API_MAX_LENGTH=\${FLOWSTACK_API_MAX_LENGTH}
      - FLOWSTACK_VOLUME_HOST_PATH=\${FLOWSTACK_VOLUME_HOST_PATH}
      - FLOWSTACK_INFLUXDB_ADMIN_TOKEN=\${FLOWSTACK_INFLUXDB_ADMIN_TOKEN}
      - FLOWSTACK_NANOMQ_PASSWORD=\${FLOWSTACK_NANOMQ_PASSWORD}
      - FLOWSTACK_NANOMQ_PASSWORD_SCADA=\${FLOWSTACK_NANOMQ_PASSWORD_SCADA}
      - FLOWSTACK_WWW_PUBLIC_URL=\${FLOWSTACK_WWW_PUBLIC_URL}
      - GRAFANA_PUBLIC_URL=\${GRAFANA_PUBLIC_URL}
      - GRAFANA_SECURITY_ADMIN_PASSWORD=\${GRAFANA_SECURITY_ADMIN_PASSWORD}
      - GRAFANA_SECURITY_ADMIN_USER=\${GRAFANA_SECURITY_ADMIN_USER}
      - INFLUXDB_ADMIN_PASSWORD=\${INFLUXDB_ADMIN_PASSWORD}
      - INFLUXDB_ADMIN_TOKEN=\${INFLUXDB_ADMIN_TOKEN}
      - MONGODB_PASSWORD=\${MONGODB_PASSWORD}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    deploy:
      resources:
        limits:
          cpus: "1"
          memory: 1024m

  nginx-proxy-manager:
    image: harbor.nexpie.com/flowstack/nginx-proxy-manager:v1.0.1-3
    ports:
      - "58081:81"
      - "80:80"
      - "443:443"
    volumes:
      - nginx-proxy-manager-data:/data
      - nginx-proxy-manager-letsencrypt:/etc/letsencrypt
    environment:
      - NPM_INIT_EMAIL=contact@nexpie.com
      - NPM_INIT_PASSWORD=\${NPM_INIT_PASSWORD}
    deploy:
      resources:
        limits:
          cpus: "0.9"
          memory: 1024m

volumes:
  flowstack-volume:
    driver: local
    driver_opts:
      device: \${FLOWSTACK_VOLUME_HOST_PATH}/
      type: none
      o: bind

  flowstack-profile:
    driver: local
    driver_opts:
      device: \${FLOWSTACK_VOLUME_HOST_PATH}/flowstack/profile
      type: none
      o: bind

  nginx-proxy-manager-data:
    driver: local
    driver_opts:
      device: \${FLOWSTACK_VOLUME_HOST_PATH}/nginx-proxy-manager/data
      type: none
      o: bind

  nginx-proxy-manager-letsencrypt:
    driver: local
    driver_opts:
      device: \${FLOWSTACK_VOLUME_HOST_PATH}/nginx-proxy-manager/letsencrypt
      type: none
      o: bind

networks:
  default:
    name: \${COMPOSE_PROJECT_NAME}
    driver: bridge
    external: true
EOF

    echo "สร้างไฟล์ docker-compose.yml สำเร็จ!"
else
    echo "ไฟล์ docker-compose.yml มีอยู่แล้ว"
fi

# ตรวจสอบและสร้างไฟล์ .env ถ้ายังไม่มี
ENV_FILE="$FLOWSTACK_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    cat <<EOF > "$ENV_FILE"
FLOWSTACK_PUBLIC_PORT=40000
FLOWSTACK_VOLUME_HOST_PATH=/usr/local/flowstack-volume
FLOWSTACK_DEPLOYMENT_MODE=CLOUD
COMPOSE_PROJECT_NAME=flowstack
NPM_INIT_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-24)
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-24)
EOF

    echo "สร้างไฟล์ .env สำเร็จ!"
else
    echo "ไฟล์ .env มีอยู่แล้ว"
fi
