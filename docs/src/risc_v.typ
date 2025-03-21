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
- *Tier 1 ("guaranteed to work")*: This means the Rust project runs automated tests (including all applicable unit tests and integration tests) on these platforms in continuous integration (CI). The compiler and standard library are expected to build successfully, pass tests, and function reliably. Pre-built binaries are officially provided for Tier 1 targets, and regressions are treated as high-priority issues.
- *Tier 2 ("guaranteed to build")*: The compiler and standard library should build successfully for these targets, and the Rust project will accept bug reports. However, not all tests may be run in CI, or they may not all pass. Official binaries may or may not be provided. While Tier 2 targets receive some level of support and oversight, they do not receive as rigorous a testing process as Tier 1.
- *Tier 3 ("may work"):* 
  These targets are minimally supported. They are generally community-maintained, and there is no official guarantee they will build or pass tests. The Rust project does not run CI for these platforms, and pre-built binaries are not typically provided. 

== RISC-V targets
RISC-V embedded targets can be categorized into 32-bit and 64-bit architectures:

- 32-bit targets:
  - riscv32{e, em, emc}-unknown-none-elf → Optimized for ultra-constrained devices (16 GPRs, minimal power/area).
  - riscv32{i, im, ima, imc, imac, imafc}-unknown-none-elf → Higher performance with 32 GPRs and optional extensions for multiplication (M), atomic operations (A), and floating-point (F).

- 64-bit targets:
  - riscv64gc → Full-featured (integer, floating-point, atomic, compressed).
  - riscv64imac → Similar but omits floating-point (F, D), balancing performance and hardware constraints.

Tier Support:
- Tier 3: riscv32{e, em, emc} and riscv32ima.
- Tier 2: Most riscv32{i, im, imc, imac, imafc} targets and both 64-bit targets.
- Note: All are no_std (no standard library support).

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
