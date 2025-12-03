#!/bin/bash

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

# เปลี่ยนไปยังโฟลเดอร์ /usr/local/flowstack
cd "$COMPOSE_DIR"

# รัน Docker Compose
echo "🚀 กำลังรัน docker-compose up -d..."
docker compose up -d
echo "✅ บริการเริ่มทำงานแล้ว!"
