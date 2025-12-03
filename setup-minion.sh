#!/bin/bash

# ตรวจสอบว่ามี Salt Minion อยู่แล้วหรือไม่
if command -v salt-minion &> /dev/null; then
    echo "✅ Salt Minion ถูกติดตั้งแล้ว: $(salt-minion --version)"
else
    echo "🚀 กำลังติดตั้ง Salt Minion..."

    # อัปเดตแพ็คเกจ
    sudo apt update

    # ติดตั้ง Salt Minion
    sudo apt install -y salt-minion

    echo "✅ Salt Minion ติดตั้งสำเร็จ!"
fi

# กำหนดค่า Salt Minion
echo "⚙️ กำลังตั้งค่า Salt Minion..."

# สำรองไฟล์การตั้งค่าก่อนแก้ไข
CONFIG_FILE="/etc/salt/minion"
BACKUP_FILE="/etc/salt/minion.bak"

if [ -f "$CONFIG_FILE" ]; then
    sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "📂 สำรองไฟล์การตั้งค่าเดิมไว้ที่ $BACKUP_FILE"
fi

# เขียนค่าการตั้งค่าใหม่ให้ Salt Minion
cat <<EOF | sudo tee "$CONFIG_FILE"
master: salt-master
#master: 47.128.64.63
# master: 35.193.46.122
# master: 203.154.183.85
publish_port: 4505
master_port: 4506
EOF

echo "✅ อัปเดตไฟล์ $CONFIG_FILE สำเร็จ!"

# รีสตาร์ทและเปิดใช้งาน Salt Minion
sudo systemctl restart salt-minion
sudo systemctl enable salt-minion

echo "✅ Salt Minion เชื่อมต่อกับ Salt Master เรียบร้อยแล้ว!"
