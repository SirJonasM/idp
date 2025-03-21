= Bare Metal <BareMetal>
!DISCLAIMER: Code is from the popovicu/risc-v-bare-metal-rust-dynamic-memory repository see @sources!
== Build
Here is a simple `Hello World` program in Rust that can be build for RISC-V and then be run by QEMU.
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
This embeds the assembly code from `entry.s` at compile time. The `entry.s` file contains critical startup instructions for our RISC-V system:
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
The linker script defines the memory layout of the program, specifying where different sections of code and data should be placed in RAM. It assigns the `text` (code), `data`, read-only data(`rodata`), and `BSS` (uninitialized data) sections to the memory region starting at `0x80000000`. Additionally, it aligns memory properly and defines `_STACK_PTR`, which sets up the stack pointer for the program. This ensures that the compiled binary is correctly structured for execution on the target RISC-V hardware.

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
== Run in QEMU
To run the program in QEMU choose the correct risc-v architecture and run 
```bash 
# for 32-Bit architectures
qemu-system-riscv32 -machine virt -bios <path/to/executable> -nographic
# or for 64-Bit architectures
qemu-system-riscv64 -machine virt -bios <path/to/executable> -nographic
```
