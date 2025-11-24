FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        git \
        curl \
        wget \
        nano \
        neofetch \
        ca-certificates \
        build-essential \
        tmate \
        && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash dockermachines && \
    echo 'dockermachines ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install desktop packages without prompts
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xvfb \
        xfce4 \
        xfce4-goodies \
        x11vnc \
        dbus-x11 \
        && rm -rf /var/lib/apt/lists/*

USER dockermachines
WORKDIR /home/dockermachines/app

RUN git clone https://github.com/WackyDawg/vps_rdp.git .

RUN npm install --only=production

EXPOSE 7860

USER root

RUN chmod +x /home/dockermachines/app/start.sh

CMD ["/home/dockermachines/app/start.sh"]