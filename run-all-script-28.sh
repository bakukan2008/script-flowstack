#!/bin/bash

# ตั้งค่าตัวแปรสำหรับไม่ให้ apt แสดง prompt
export DEBIAN_FRONTEND=noninteractive

install_salt_minion() {
    echo "🚀 กำลังติดตั้ง Salt Minion..."

    # อัปเดตแพ็กเกจและติดตั้ง dependencies
    sudo apt update && sudo apt install -y curl gnupg2 software-properties-common

    # สร้างโฟลเดอร์ keyrings
    mkdir -p /etc/apt/keyrings

    # ดาวน์โหลดและเพิ่ม SaltStack GPG Key
    curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public \
        | tee /etc/apt/keyrings/salt-archive-keyring.pgp > /dev/null

    # เพิ่มแหล่งแพ็กเกจของ SaltStack
    curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources \
        | tee /etc/apt/sources.list.d/salt.sources > /dev/null

    # อัปเดตและติดตั้ง Salt Minion
    sudo apt update && sudo apt install -y salt-minion

    # กำหนดค่า Salt Minion ให้เชื่อมต่อกับ Salt Master
    SALT_MASTER="192.168.100.1"
    echo "master: $SALT_MASTER" | sudo tee /etc/salt/minion

    # รีสตาร์ทและเปิดใช้งาน Salt Minion
    sudo systemctl restart salt-minion
    sudo systemctl enable salt-minion

    echo "✅ Salt Minion ติดตั้งและเชื่อมต่อกับ $SALT_MASTER สำเร็จ!"
}

install_docker() {
    echo "🚀 กำลังติดตั้ง Docker (เวอร์ชัน 28.x.x)..."

    # ลบแพ็คเกจที่อาจขัดแย้งกัน
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
        sudo apt-get remove -y $pkg 
    done

    # อัปเดตระบบและติดตั้งแพ็คเกจที่จำเป็น
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg

    # สร้างโฟลเดอร์สำหรับ key และดาวน์โหลด GPG key ของ Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # เพิ่ม repository ของ Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # อัปเดตระบบอีกครั้ง
    sudo apt-get update

    echo "🔍 ตรวจสอบเวอร์ชัน Docker 28.x.x ที่มีให้ติดตั้ง..."
    DOCKER_VERSION=$(apt-cache madison docker-ce | awk '/28\./ {print $3}' | head -n 1)

    if [ -z "$DOCKER_VERSION" ]; then
        echo "❌ ไม่พบ Docker เวอร์ชัน 28.x.x ใน repository!"
        exit 1
    fi

    echo "➡️ จะติดตั้ง Docker เวอร์ชัน: $DOCKER_VERSION"

    # ติดตั้ง Docker CE version 28.x.x
    sudo apt-get install -y \
        docker-ce="$DOCKER_VERSION" \
        docker-ce-cli="$DOCKER_VERSION" \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    # เปิดใช้งาน Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Lock version ป้องกันการอัปเดต
    sudo apt-mark hold docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin

    # เข้าสู่ระบบ Harbor
    echo "🚀 เข้าสู่ระบบ Docker Harbor..."
    docker login harbor.nexpie.com -u robot\$flowstack-token -p U3ecZdKbBC08JsHu5d33gBjrE7EAnHbP
    docker login dock.nexiiot.io -u robot\$pull-flowstack -p nhafR7SaNoJottQ6bUHpk9yK1FoQBteO
    echo "✅ Docker login สำเร็จ!"
}


setup_flowstack() {
    echo "🚀 กำลังตั้งค่า Flowstack..."

    FLOWSTACK_DIR="/usr/local/flowstack"

    # ตรวจสอบและสร้างโฟลเดอร์ flowstack ถ้ายังไม่มี
    if [ ! -d "$FLOWSTACK_DIR" ]; then
        mkdir -p "$FLOWSTACK_DIR"
        echo "✅ สร้างโฟลเดอร์ $FLOWSTACK_DIR สำเร็จ!"
    else
        echo "🔎 โฟลเดอร์ $FLOWSTACK_DIR มีอยู่แล้ว"
    fi

    # ตรวจสอบและสร้างไฟล์ docker-compose.yml ถ้ายังไม่มี
    DOCKER_COMPOSE_FILE="$FLOWSTACK_DIR/docker-compose.yml"
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        cat <<EOF > "$DOCKER_COMPOSE_FILE"
services:
  flowstack:
    image: dock.nexiiot.io/application/flowstack:2.0-307-a4643a10
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
        echo "✅ สร้างไฟล์ docker-compose.yml สำเร็จ!"
    else
        echo "🔎 ไฟล์ docker-compose.yml มีอยู่แล้ว"
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
        echo "✅ สร้างไฟล์ .env สำเร็จ!"
    else
        echo "🔎 ไฟล์ .env มีอยู่แล้ว"
    fi
}
#!/bin/bash

setup_volume() {
    echo "🚀 กำลังตั้งค่า Volume สำหรับ Flowstack..."

    # รายการโฟลเดอร์ที่จะสร้าง
    DIRS=(
        "/usr/local/flowstack-volume"
        "/usr/local/flowstack-volume/flowengine"
        "/usr/local/flowstack-volume/flowengine/flowdata"
        "/usr/local/flowstack-volume/nginx-proxy-manager"
        "/usr/local/flowstack-volume/nginx-proxy-manager/letsencrypt"
        "/usr/local/flowstack-volume/nginx-proxy-manager/data"
        "/usr/local/flowstack-volume/flowstack-store"
        "/usr/local/flowstack-volume/flowstack"
        "/usr/local/flowstack-volume/flowstack/profile"
    )

    # วนลูปตรวจสอบและสร้างโฟลเดอร์หากไม่มีอยู่
    for dir in "${DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "✅ สร้างโฟลเดอร์ $dir สำเร็จ!"
        else
            echo "🔎 โฟลเดอร์ $dir มีอยู่แล้ว"
        fi
    done

    echo "✅ การตั้งค่า Volume เสร็จสมบูรณ์!"
}
#!/bin/bash

compose_flowstack() {
    echo "🚀 กำลังตรวจสอบและรัน Flowstack Compose..."

    # ตรวจสอบว่ามี Docker Network อยู่แล้วหรือไม่
    if docker network ls | grep -q "flowstack"; then
        echo "✅ Docker Network 'flowstack' มีอยู่แล้ว"
    else
        echo "🚀 กำลังสร้าง Docker Network 'flowstack'..."
        docker network create flowstack
        echo "✅ สร้างสำเร็จ!"
    fi

    # ตรวจสอบว่ามีไฟล์ docker-compose.yml อยู่หรือไม่
    COMPOSE_DIR="/usr/local/flowstack"
    COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "❌ ไม่พบไฟล์ docker-compose.yml ที่ $COMPOSE_DIR"
        exit 1
    fi

    # เปลี่ยนไปยังโฟลเดอร์ Flowstack
    cd "$COMPOSE_DIR"

    # รัน Docker Compose
    echo "🚀 กำลังรัน docker-compose up -d..."
    docker compose up -d
    echo "✅ บริการเริ่มทำงานแล้ว!"
}



# install_salt_minion && echo "✅ ติดตั้ง Salt Minion สำเร็จ!"
install_docker && echo "✅ ติดตั้ง Docker สำเร็จ!"
setup_flowstack && echo "✅ ตั้งค่า Flowstack สำเร็จ!"
setup_volume && echo "✅ ตั้งค่า Volume สำเร็จ!"
compose_flowstack && echo "✅ รัน Flowstack Compose สำเร็จ!"
