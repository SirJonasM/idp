= Building Rust for RISC-V RTEMS
!DISCLAIMER: Code is from the RTEMS Documentation see @sources!
== RTEMS
RTEMS (Real-Time Executive for Multiprocessor Systems) is a free, open-source real-time operating system (RTOS) designed for embedded systems. It provides a POSIX-compliant API, supports multiprocessing, and is used in aerospace, automotive, industrial, and military applications. RTEMS is lightweight, highly configurable, and optimized for deterministic real-time performance, making it ideal for mission-critical systems.

The RTEMS Documentation (see @sources) has a guide to Build Bare Metal Rust for RTEMS. It explains the general way on how to build Rust for RTEMS and then shows how to execute it in QEMU.

What is needed:
- RTEMS Tools to build BSP and the linking process.
- Configuration file `init.c` for RTEMS.
- A Board Support Package.
- A prepared Rust Project for RTEMS.

== Board Support Package (BSP)
A Board Support Package (BSP) in RTEMS is a collection of low-level software components that enable RTEMS to run on a specific hardware platform. It includes CPU initialization, clock setup, interrupt handling, memory management, and device drivers. The BSP abstracts hardware differences, making RTEMS portable across multiple architectures.

RTEMS supports RISC-V architecture with BSPs for platforms such as QEMU RISC-V emulation. These BSPs provide essential support for booting, handling interrupts, and managing peripherals, allowing RTEMS applications to run on real and emulated RISC-V hardware.

A BSP can be configured for more specific cases. The configuration is done when building the specifig BSP via a a `ini` file. Configuration options can be listed by running the command line tool `waf` from the RTEMS repository with the `bspdefaults` subcommand.
Here is a snippet of the command output for the target `riscv/rv32i`:
```bash
λ ./waf bspdefaults --rtems-bsp=riscv/rv32i
# boot hartid (processor number) of risc-v cpu (default 0)
RISCV_BOOT_HARTID = 0
# Defines the build label returned by rtems_get_build_label().
RTEMS_BUILD_LABEL = DEFAULT
# Default size in CAN frames of FIFO queues.
RTEMS_CAN_FIFO_SIZE = 64
# Number of available priorities for CAN priority queues.
RTEMS_CAN_QUEUE_PRIO_NR = 3
# Enable the RTEMS internal debug support
RTEMS_DEBUG = False
# Enable the Driver Manager startup
RTEMS_DRVMGR_STARTUP = False
# Enable the Newlib C library support
RTEMS_NEWLIB = True
# Enable the para-virtualization support
RTEMS_PARAVIRT = False
```
== Rust Project for RISC-V RTEMS
The setup for a Rust project in this enviroment is similar to the Bare Metal from @BareMetal. Except there is now no linker script and no start up assmeby file needed. 

RTEMS also provides allocater functions that rust can be linked to to enable dynamic memory. Aswell as a print function `printk()` to write to a console.
Similar to the Pure Bare Metal approach rust needs to have a panic handler but here it can be forwarded to the rtems_panic handler `rtems_panic()`

The entry point to the program is a function that has to be implemented as 
```rust
#[unsafe(no_mangle)]
extern "C" fn Init() {...}
```
Before exiting the program the RTEMS `rtems_shutdown_executive` is called to shutdown the RTMES system in a controlled manner.

To specify some build flags a `.cargo/config.toml` is defined where the configuration for cargo is defined. In it targets can be defined and configured.
Here is a example to build for a the `riscv64gc-unknown-none-elf` target:
```toml
[target.riscv64gc-unknown-none-elf]
# Either kind should work as a linker
linker = "riscv-rtems7-gcc"
# linker = "riscv-rtems7-clang"
rustflags = [
    # See `rustc --target=riscv64gc-unknown-none-elf  --print target-cpus`
    "-Ctarget-cpu=generic-rv64",
    # The linker is a gcc compatible C Compiler
    "-Clinker-flavor=gcc",
    # Pass these options to the linker
    "-Clink-arg=-march=rv64imafdc",
    "-Clink-arg=-mabi=lp64d",
    "-Clink-arg=-mcmodel=medany",
    # Rust needs libatomic.a to satisfy Rust's compiler-builtin library
    "-Clink-arg=-latomic",
]
runner = "qemu-system-riscv64 -M virt -nographic -bios"
```

The project can then be build with `cargo build`. The target of the BSP and the rustc target have to be same to assure compatibility.

== Linking and running in QEMU
Linking is done by compiling the RTEMS init.c and then using the RTEMS toolchain to link it with the Rust static library. In this process linker flags that are defined by the used BSP are used.

This produces a `<project-name>.exe` that then can be run in QEMU with:
```bash
rtems-run --rtems-bsp=<bsp_name> <project_name>.exe
```


