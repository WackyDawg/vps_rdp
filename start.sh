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

echo "Installing Antidetect Browser...."
wget -q https://version.adspower.net/software/linux-x64-global/7.7.18/AdsPower-Global-7.7.18-x64.deb
dpkg -i AdsPower-Global-7.7.18-x64.deb || apt-get install -f -y
dpkg -i AdsPower-Global-7.7.18-x64.deb
rm AdsPower-Global-7.7.18-x64.deb

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

echo "Installing audio dependencies..."
apt-get install -y \
    pulseaudio \
    pulseaudio-utils \
    alsa-utils \
    pavucontrol \
    libpulse0

echo "Installing OBS Studio (latest from GitHub)..."
apt-get install -y software-properties-common libgl1 libpulse0 libxcb-xinerama0 libxcb-randr0

OBS_VERSION=$(curl -s https://api.github.com/repos/obsproject/obs-studio/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "Installing OBS $OBS_VERSION..."

wget -q "https://github.com/obsproject/obs-studio/releases/download/${OBS_VERSION}/OBS-Studio-${OBS_VERSION}-Ubuntu-x86_64.deb" -O obs-studio.deb \
  || wget -q "https://github.com/obsproject/obs-studio/releases/download/${OBS_VERSION}/obs-studio_${OBS_VERSION}_amd64.deb" -O obs-studio.deb

dpkg -i obs-studio.deb || apt-get install -f -y
dpkg -i obs-studio.deb
rm obs-studio.deb

echo "Desktop user already configured..."
echo "Killing any existing processes..."
pkill -9 rustdesk || true
pkill -9 Xvfb || true
pkill -9 xfce4 || true
pkill -9 pulseaudio || true
sleep 2

echo "Starting virtual display and desktop..."
su - desktopuser << 'EOF'
export DISPLAY=:99
export NO_AT_BRIDGE=1
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export PULSE_SERVER=unix:/tmp/pulse-socket

mkdir -p ~/logs

# Start Xvfb with full HD resolution
Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset > ~/logs/xvfb.log 2>&1 &
sleep 2

# Start PulseAudio with virtual null sinks
pulseaudio --start \
    --exit-idle-time=-1 \
    --load="module-null-sink sink_name=virtual_out sink_properties=device.description=VirtualOutput" \
    --load="module-null-sink sink_name=virtual_mic sink_properties=device.description=VirtualMic" \
    --load="module-virtual-source source_name=virtual_mic_source master=virtual_mic.monitor" \
    --log-target=file:${HOME}/logs/pulseaudio.log 2>&1 || true
sleep 2

# Set defaults
pactl set-default-sink virtual_out || true
pactl set-default-source virtual_mic_source || true

# Start XFCE
startxfce4 > ~/logs/xfce.log 2>&1 &
sleep 5

# Start RustDesk
rustdesk > ~/logs/rustdesk.log 2>&1 &
sleep 3

# Start OBS minimized
obs --startrecording --minimize-to-tray > ~/logs/obs.log 2>&1 &
sleep 3

# Check processes
ps aux | grep -E "rustdesk|obs|pulseaudio" | grep -v grep
EOF

echo "Configuring RustDesk..."
rustdesk --password WackydawgTheBotFather

echo "========================================="
echo "RustDesk ID:"
su - desktopuser -c "rustdesk --get-id" || rustdesk --get-id
echo "RustDesk Password: WackydawgTheBotFather"
echo "========================================="

echo "RustDesk Status:"
su - desktopuser -c "tail -20 ~/logs/rustdesk.log"

echo "OBS Status:"
su - desktopuser -c "tail -10 ~/logs/obs.log" || true

echo "Audio Status:"
su - desktopuser -c "PULSE_SERVER=unix:/tmp/pulse-socket pactl list sinks short" || true

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

echo "Silently ping the server every 5sec...."
while true; do curl -s -o /dev/null http://localhost:7860; sleep 5; done &
