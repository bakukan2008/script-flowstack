#!/bin/bash

        # ตรวจสอบว่ามี Docker อยู่แล้วหรือไม่
        if command -v docker &> /dev/null; then
            echo "Docker ถูกติดตั้งแล้ว: $(docker --version)"
        else
            echo "กำลังติดตั้ง Docker..."

            # ลบแพ็คเกจที่อาจขัดแย้งกัน
            for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
                sudo apt-get remove -y $pkg 
            done

            # อัปเดตระบบและติดตั้งแพ็คเกจที่จำเป็น
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl

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

            # ติดตั้ง Docker
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # เปิดใช้งาน Docker
            sudo systemctl start docker
            sudo systemctl enable docker
        fi

        # เข้าสู่ระบบ Harbor
        echo "เข้าสู่ระบบ Docker Harbor..."
        docker login harbor.nexpie.com -u robot\$flowstack-token -p U3ecZdKbBC08JsHu5d33gBjrE7EAnHbP

        echo "Docker login สำเร็จ!"
