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

== The Rust Allocator
In `no_std` environments, such as embedded systems, Rust’s standard memory allocator is not available. This makes it necessary to define a custom allocator or use an external allocator provided by the operating system. Without a proper allocator, heap allocation features like `Box`, `Vec`, and `String` cannot be used.

Rust provides the `#[global_allocator]` attribute to specify a custom global memory allocator. This is useful in environments where the default allocator is unavailable or needs to be replaced.

The `#[global_allocator]` attribute sets a static instance of a type implementing `GlobalAlloc` as the global allocator.
For no_std environments, a simple custom allocator can be implemented as follows:
```rust
use core::alloc::{GlobalAlloc, Layout};

struct SimpleAllocator;

unsafe impl GlobalAlloc for SimpleAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        // Allocator logic will go here
    }

    unsafe fn dealloc(&self, _ptr: *mut u8, _layout: Layout) {
        // Deallocator logic will go here
    }
}

#[global_allocator]
static ALLOCATOR: SimpleAllocator = SimpleAllocator;
```
This basic example demonstrates how a custom allocator could be structured. In real scenarios, the `alloc` function would point to a memory pool, and `dealloc` would properly release memory.

It is also possible to use `extern functions` to import functions in the linking process. This is done by declaring them with the `extern` keyword:
```rust
extern "C" {
    fn malloc(size: usize) -> *mut u8;
    fn free(ptr: *mut u8);
}
```
