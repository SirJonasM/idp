# Bare Metal Rust Example
This Project ist based on [16.1. Bare Metal Rust with RTEMS — RTEMS User Manual 7.1dd7891 (4th March 2025) documentation](https://docs.rtems.org/docs/main/user/rust/bare-metal.html#)

Get this Dockerfile 
``` Dockerfile
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
```
Run it with:
``` bash
podman build -t rtems_rust .
podman run -it --name=rusty_rtems rtems_rust bash
```
Build RTEMS tools with: 
``` bash
git clone https://gitlab.rtems.org/rtems/tools/rtems-source-builder.git rsb
cd rsb/rtems
../source-builder/sb-set-builder --prefix /opt/rtems/7 \
    7/rtems-sparc \
    7/rtems-riscv
cd ../..
```
Export some variables to PATH:
``` bash
export PATH=/opt/rtems/7/bin:${PATH}
```
Check versions:
```bash
sparc-rtems7-gcc --version
riscv-rtems7-gcc --version
```
Build RTEMS:
```bash
git clone https://gitlab.rtems.org/rtems/rtos/rtems.git
cd rtems
```
Create config.ini file:
``` ini
[sparc/leon3]
RTEMS_SMP = True
[riscv/rv64imafdc]
```
Build and install rtems
``` bash
./waf configure --prefix=/opt/rtems/7
./waf
./waf install
```
Run some tests:
```bash
sparc-rtems7-sis -leon3 -nouartrx -r m 4 \
    build/sparc/leon3/testsuites/samples/hello.exe
sparc-rtems7-sis -leon3 -nouartrx -r m 4 \
    build/sparc/leon3/testsuites/samples/ticker.exe
qemu-system-riscv64 -M virt -nographic -bios \
    build/riscv/rv64imafdc/testsuites/samples/hello.exe
qemu-system-riscv64 -M virt -nographic -bios \
    build/riscv/rv64imafdc/testsuites/samples/ticker.exe
```
Exit:
```bash
cd ..
```
Install rust:
``` bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustup update
cargo --version
rustup target add riscv64gc-unknown-none-elf
```
Clone and build this project.
``` bash
git clone https://github.com/SirJonasM/bare-metal-rust-example.git
or: 
git clonegit@github.com:SirJonasM/bare-metal-rust-example.git
cd bare-metal-rust-example
cargo build --target=riscv64gc-unknown-none-elf
```
Build init.c and linkt to rust project:
``` bash
export PKG_CONFIG_RISCV=/opt/rtems/7/lib/pkgconfig/riscv-rtems7-rv64imafdc.pc

riscv-rtems7-gcc -Wall -Wextra -O2 -g \
    -fdata-sections -ffunction-sections \
    $(pkg-config --cflags ${PKG_CONFIG_RISCV}) init.c -c -o init_riscv.o

riscv-rtems7-gcc init_riscv.o
 -Ltarget/riscv64gc-unknown-none-elf/debug   -lhello_rtems   -ohello_rtems_riscv.exe   $(pkg-config --variable=ABI_FLAGS ${PKG_CONFIG_RISCV})   $(pkg-config --libs ${PKG_CONFIG_RISCV})
```

Run in emulator:
```bash
rtems-run --rtems-bsp=rv64imafdc hello_rtems_riscv.exe
```



