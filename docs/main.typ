#let title-page(title:[], email:str, author: [], body) = {
  set page(margin: (top: 1.5in, rest: 2in))
  set text(size: 16pt)
  set heading(numbering: "1.1.1")
  line(start: (0%, 0%), end: (8.5in, 0%), stroke: (thickness: 2pt))
  align(horizon + left)[
    #text(size: 24pt, title)\
    #v(1em)
    Rust für FPGA-SoC mit RISC-V: Evaluierung von Sicherheit und Performance
    #v(1em)
    #text(size:16pt, author)
    #linebreak()
    #v(1em)
    #linebreak()
    #link("mailto:" + email, email)
  ]
  align(bottom + left)[#datetime.today().display()]
  set page(fill: none, margin: auto)
  pagebreak()
  body
}

#show: body => title-page(
  title: [Interdisziplinare Projekt],
  email:"12mojo1bif@hft-stuttgart.de",
  author: [Jonas Möwes],
  body
)
#set page(paper: "a4")
#set text(size: 11pt)
#show link: underline
#counter(page).update(1)
#set page(paper: "a4", header: [Jonas Möwes #h(1fr) IDP #h(1fr) Hochschule für Technik], numbering: "-1-")
= Building Rust for RISC-V
== RISC-V
RISC-V is an open standard instruction set architecture (ISA) defined by the RISC-V Foundation. It is designed with a modular philosophy, consisting of a small base integer instruction set plus optional extensions like M (multiply/divide), A (atomic operations), F and D (floating-point), and more. This flexibility makes RISC-V suitable for everything from microcontrollers to high-performance computing. Because the ISA is open and free to implement, it has spurred innovation and adoption in academic, industrial, and hobbyist contexts. When building Rust for RISC-V, it is critical to select the correct variant of the base ISA and extensions supported by your target device or emulator.
== Rustc platform support
Rustc is the compiler for the programming language Rust. It supports various platforms like Linux, Windows, Mac and as well to some extend RISC-V.
The platforms also called targets are seperated in tiers that guarentee different aspects. 
The target names follow the LLVM target triple naming convention defined in #link("https://llvm.org/doxygen/Triple_8h_source.html")[llvm::Triple class].

The syntax is: ``` <arch><sub_arch>-<vendor>-<sys>-<env>```

For example: ``` riscv64gc-unknown-linux-gnu``` would translate to:
- *riscv64gc:* 64-bit RISC-V architecture with the G (I+M+A+F+D) + C (compressed) instruction-set extensions
- *unknown:* vendor is unspecified (could be any)
- *linux:* the target operating system is Linux
- *gnu:* indicates the GNU C library (glibc) environment and toolchain conventions for Linux

Each target is put into a tier. There are 3 tiers:
- *Tier 1 ("guarenteed to work")*: This means the Rust project runs automated tests (including all applicable unit tests and integration tests) on these platforms in continuous integration (CI). The compiler and standard library are expected to build successfully, pass tests, and function reliably. Pre-built binaries are officially provided for Tier 1 targets, and regressions are treated as high-priority issues.
- *Tier 2 ("guarenteed to build")*: The compiler and standard library should build successfully for these targets, and the Rust project will accept bug reports. However, not all tests may be run in CI, or they may not all pass. Official binaries may or may not be provided. While Tier 2 targets receive some level of support and oversight, they do not receive as rigorous a testing process as Tier 1.
- *Tier 3 ("may work"):* 
  These targets are minimally supported. They are generally community-maintained, and there is no official guarantee they will build or pass tests. The Rust project does not run CI for these platforms, and pre-built binaries are not typically provided. If you encounter issues, you are welcome to file bug reports, but fixes and support are on a best-effort basis by contributors.

Host Tools:
Host tools refer to the programs you run directly on your development machine (the “host”)—namely:
- rustc (the Rust compiler)
- cargo (the Rust package manager)
- rustdoc (the documentation generator)
- rustup (the toolchain manager)

For a target to function as a host, there must be enough tooling support to compile and run these programs locally. Usually, Tier 1 platforms are considered fully supported hosts (meaning you can download official host tool binaries), while Tier 2 and Tier 3 may or may not have the same level of host tool support. If a platform is not supported as a host, you can still cross-compile Rust code for that platform from a different Tier 1 or Tier 2 host machine.
== RISC-V targets
There are two groups of targets for a RISC-V 32-Bit architecture that are suitable for an embedded environment:

`riscv32{e, em, emc}-unknown-none-elf` is built around the E (“Embedded”) base instruction set, which provides only 16 general-purpose registers (GPRs). This smaller register file is ideal for ultra-constrained devices where minimal area and power consumption are paramount. Depending on the variant, it can also include extensions like M for hardware multiply/divide and C for compressed instructions, further tailoring the architecture to small-footprint, low-power scenarios.

`riscv32{i, im, ima, imc, imac, imafc}-unknown-none-elf` instead uses the I (“Base Integer”) set, which has 32 GPRs. This allows for higher performance, making it more suitable for embedded applications that can afford a slightly larger hardware footprint. In addition to the M (multiply/divide) and C (compressed) extensions, Group 2 can include A (atomic instructions) for concurrency and F (single-precision floating point) for mathematical operations, providing a more feature-rich instruction set for less constrained environments.

And then there are two targets for the RISC-V 64-Bit architecture that are suitable for an embedded environment:

`riscv64gc-unknown-none-elf` uses the 64-bit RISC-V instruction set with the “G” extension (I, M, A, F, D) plus “C” (compressed instructions). This combination covers virtually all general-purpose features—from integer and floating-point arithmetic to atomics—while maintaining an efficient code footprint.

`riscv64imac-unknown-none-elf` likewise targets a 64-bit RISC-V environment but omits the floating-point extensions (F and D). Instead, it focuses on the I (base integer), M (multiply/divide), A (atomics), and C (compressed) extensions, balancing performance with fewer hardware requirements.

All targets in Group 1 `riscv32{e, em, emc}-unknown-none-elf` fall under Tier 3, while Group 2 `riscv32{i, im, ima, imc, imac, imafc}-unknown-none-elf` is predominantly Tier 2, except for `riscv32ima`, which remains Tier 3. Both 64-Bit targets are tier 2. It is also important to note that none of these targets include standard library support (i.e., they are no_std).
= QEMU
QEMU is an open-source machine emulator and virtualizer that can simulate a wide range of CPU architectures, including RISC-V. By running your program on QEMU, you can develop and test embedded applications without needing the actual hardware. For a RISC-V 32-bit setup (e.g., riscv32i), you typically invoke QEMU with a command like:
```sh
qemu-system-riscv32 \
    -nographic \
    -machine virt \
    -kernel path/to/your_program.elf
```
Here, -machine virt selects the generic RISC-V “virt” machine, while -nographic routes I/O through the terminal rather than a graphical console. You can then observe your program’s output and interact with it as though it were running on physical hardware. This approach is especially helpful during early development, debugging, and continuous integration on embedded targets.
= Bare Metal
== Build
Here is a simple Hello World program in Rust that can be build for RISC-V and then be run by qemu. 
```rust
#![no_std] // 1
#![no_main] // 2

use core::arch::global_asm;
use core::panic::PanicInfo;
use core::ptr;

global_asm!(include_str!("entry.s")); // 3

const UART: *mut u8 = 0x10000000 as *mut u8; //4
fn uart_print(message: &str) {
    for c in message.chars() {
        unsafe {
            ptr::write_volatile(UART, c as u8);
        }
    }
}

// 5
#[no_mangle]
pub extern "C" fn main() -> ! {
    loop {
        uart_print("Hello, world!\n");
        for _ in 0..5000000 {}
    }
}
// 6
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    uart_print("Something went wrong.");
    loop {}
}
```
There are 6 key points that are important.
1. `#![no_std]`
This attribute tells the Rust compiler not to use the standard library (std). In embedded and bare-metal environments, you typically don’t have an operating system or the usual platform features that std depends on, so you opt for no_std instead.

2. `#![no_main]`
Rust normally expects a main() function as the entry point, but in a bare-metal environment, you have full control over what “entry” means (often defined by a custom linker script and/or assembly). Marking the crate with `#![no_main]` ensures that Rust does not generate the usual runtime setup and main() boilerplate.

3. `global_asm!(include_str!("entry.s"));`
This embeds the assembly code from entry.s at compile time. The entry.s file contains critical startup instructions for our RISC-V system:
```asm
.global _start
.extern _STACK_PTR

.section .text.boot

_start: 
  la sp, _STACK_PTR  # Load stack pointer
  jal main           # Jump to Rust's main function
  j .                # Infinite loop (if main ever returns)

```
- `_start` is the is the entry point, setting the stack pointer (`sp`) before jumping to `main`.
- `_STACK_PTR` is defined later in the linker script (see below).
4. `const UART: *mut u8 = 0x10000000 as *mut u8;`
This line defines a memory-mapped I/O address for a UART (Universal Asynchronous Receiver/Transmitter). In many embedded systems, hardware registers for peripherals like UART are accessed at specific memory addresses. By casting `0x10000000` to `*mut u8`, you can write bytes directly to that address to send characters.

5. `#[no_mangle] pub extern "C" fn main() -> ! { ... }`

`#[no_mangle]`: Tells the compiler not to rename (mangle) the function symbol, so the linker sees it as main.
  
`extern "C":` Ensures the function uses the C calling convention, which is typically expected in low-level contexts.

`-> !`: Indicates the function never returns (an infinite loop).
    In this function, the code repeatedly prints “Hello, world!” via the UART and does a busy-wait delay.

6. `#[panic_handler] fn panic(_info: &PanicInfo) -> ! { ... }`
When a Rust panic occurs in a no_std context, you need a custom panic handler because there is no standard library to handle panics. This function logs an error message (“Something went wrong.”) to the UART and enters an infinite loop, preventing any further execution.

In a bare-metal environment, there is no operating system to manage memory and load executables. Instead, we use a linker script to define how the program is placed in memory, ensuring that everything is correctly positioned for execution. Below is the linker script used for this RISC-V program, followed by an explanation of its purpose.

```ld 
MEMORY {
  program (rwx) : ORIGIN = 0x80000000, LENGTH = 2 * 1024 * 1024
}

SECTIONS {
  .text.boot : {
    *(.text.boot)
  } > program

  .text : {
    *(.text)
  } > program

  .data : {
    *(.data)
  } > program

  .rodata : {
    *(.rodata)
  } > program

  .bss : {
    *(.bss)
  } > program

  . = ALIGN(8);
  . = . + 4096;
  _STACK_PTR = .;
}
```
The linker script defines the memory layout of the program, specifying where different sections of code and data should be placed in RAM. It assigns the text (code), data, read-only data, and BSS (uninitialized data) sections to the memory region starting at `0x80000000`. Additionally, it aligns memory properly and defines `_STACK_PTR`, which sets up the stack pointer for the program. This ensures that the compiled binary is correctly structured for execution on the target RISC-V hardware.

There are several ways to tell cargo to use the link script but one simple way is to add a build script `build.rs` in the root of the project next to the link script.

The `build.rs` looks like this:
```rust
fn main() {
    println!("cargo:rustc-link-arg-bin=<rust-project-name>=-Tlink_script.ld");
}
```

The build process is started with the command:
```bash
cargo build --target <target>
```
== Run in qemu
To run it in qemu choose the correct risc-v architecture and run 
```bash 
# for 32-Bit architectures
qemu-system-riscv32 -machine virt -bios <path/to/executable> -nographic
# or for 64-Bit architectures
qemu-system-riscv64 -machine virt -bios <path/to/executable> -nographic
```
== Allocator

= Building Rust for RISC-V RTEMS
== RTEMS
== BSP
== Linking
== Allocator
= Milestones
Here the Milestones of the comming Bachelor Thesis is explained.
= Sources 

- #link("https://doc.rust-lang.org/rustc/platform-support.html")[The rustc book]
- #link("https://docs.rtems.org/docs/main/user/rust/bare-metal.html")[16.1. Bare Metal Rust with RTEMS — RTEMS User Manual 7.e8e6f12 (8th March 2025) documentation]
All the code for the bare metal section was provided by #link("https://popovicu.com/posts/bare-metal-rust-risc-v-with-dynamic-memory/")[Bare Metal Rust on RISC-V With Dynamic Memory]. But it was simplified to a plain Hello-World Program.
