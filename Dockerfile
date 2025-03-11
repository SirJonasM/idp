# Dockerfile to build a container image to use Rust on top of RTEMS
FROM ubuntu:24.04
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
        bison \
        build-essential \
        curl \
        flex \
        g++ \
        gdb \
        git \
        libncurses5-dev \
        ninja-build \
        pax \
        pkg-config \
        python3-dev \
        python-is-python3 \
        qemu-system-misc \
        texinfo \
        unzip \
        vim \
        zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN useradd -c "Rust Developer" -g "users" \
            -d "/home/ferris" --create-home "ferris" && \
    mkdir -p /opt/rtems && \
    chown ferris:users /opt/rtems && \
    runuser -u ferris echo \
            'export PATH=/opt/rtems/7/bin:${PATH}' \
            >>/home/ferris/.bashrc
USER ferris
WORKDIR /home/ferris
CMD ["/bin/bash"]
