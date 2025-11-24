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

echo "Installing graphics dependencies..."
apt-get install -y \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libegl1-mesa \
    libgbm1 \
    libxcb-xfixes0 \
    libxcb-shape0 \
    libxkbcommon0 \
    at-spi2-core \
    mesa-utils

echo "Creating desktop user..."
useradd -m -s /bin/bash desktopuser || true
echo "desktopuser:password123" | chpasswd

echo "Killing any existing processes..."
pkill -9 rustdesk || true
pkill -9 Xvfb || true
pkill -9 xfce4 || true
sleep 2

echo "Starting virtual display and desktop..."
su - desktopuser << 'EOF'
export DISPLAY=:99
export NO_AT_BRIDGE=1
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
mkdir -p ~/logs

# Start Xvfb with full HD resolution for better RustDesk experience
Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset > ~/logs/xvfb.log 2>&1 &
sleep 2

# Start XFCE
startxfce4 > ~/logs/xfce.log 2>&1 &
sleep 5

# Start RustDesk with error logging
rustdesk > ~/logs/rustdesk.log 2>&1 &
sleep 3

# Check if RustDesk is running
ps aux | grep rustdesk | grep -v grep
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

# Check RustDesk status
echo "RustDesk Status:"
su - desktopuser -c "tail -20 ~/logs/rustdesk.log"

# Optional: Start VNC for debugging (port 5900)
# x11vnc -display :99 -forever -shared -rfbport 5900 -nopw > /tmp/vnc.log 2>&1 &

tmate -S /tmp/tmate.sock new-session -d

echo "Waiting for tmate session..."
tmate -S /tmp/tmate.sock wait tmate-ready

echo "=== tmate SSH session ==="
tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}'
echo "=== tmate Web session ==="
tmate -S /tmp/tmate.sock display -p '#{tmate_web}'

echo "Starting Node.js server..."
cd /home/dockermachines/app
node server.js