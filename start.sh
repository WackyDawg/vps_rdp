#!/bin/bash
set -e

echo "Updating and upgrading packages..."
sudo apt-get update

echo "Installing Chrome..."
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb || apt-get install -f -y
dpkg -i google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

echo "Installing RustDesk..."
wget -q https://github.com/rustdesk/rustdesk/releases/download/1.3.2/rustdesk-1.3.2-x86_64.deb
dpkg -i rustdesk-1.3.2-x86_64.deb || apt-get install -f -y
dpkg -i rustdesk-1.3.2-x86_64.deb
rm rustdesk-1.3.2-x86_64.deb

echo "Creating desktop user..."
useradd -m -s /bin/bash desktopuser || true
echo "desktopuser:password123" | chpasswd

echo "Starting virtual display and desktop..."
su - desktopuser << 'EOF'
export DISPLAY=:99
mkdir -p ~/logs

# Start Xvfb
Xvfb :99 -screen 0 1280x720x16 -ac +extension GLX +render -noreset > ~/logs/xvfb.log 2>&1 &
sleep 2

# Start XFCE
startxfce4 > ~/logs/xfce.log 2>&1 &
sleep 5

# Start RustDesk
rustdesk > ~/logs/rustdesk.log 2>&1 &
sleep 3
EOF

echo "Configuring RustDesk..."
# Set password as root
rustdesk --password WackydawgTheBotFather

# Get and display the ID
echo "========================================="
echo "RustDesk ID:"
su - desktopuser -c "rustdesk --get-id" || rustdesk --get-id
echo "RustDesk Password: WackydawgTheBotFather"
echo "========================================="

# Optional: Start VNC for debugging (port 5900)
# x11vnc -display :99 -forever -shared -rfbport 5900 -nopw > /tmp/vnc.log 2>&1 &

echo "Starting Node.js server..."
cd /home/dockermachines/app
node server.js