#!/bin/bash

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
                echo "สร้างโฟลเดอร์ $dir สำเร็จ!"
            else
                echo "โฟลเดอร์ $dir มีอยู่แล้ว"
            fi
        done
