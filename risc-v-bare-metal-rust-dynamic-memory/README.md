# RISC-V Bare Metal Rust example (with dynamic memory allocation)

This example must be built with nightly `cargo`, and the target `riscv64gc-unknown-none-elf` must be installed to the nightly.

1. `rustup toolchain install nightly`
2. `rustup +nightly target add riscv64gc-unknown-none-elf`

Build with:

```
cargo +nightly build --bin risc-v-rust-bare-metal
```

Run on QEMU:

```
qemu-system-riscv64 -machine virt -bios target/riscv64gc-unknown-none-elf/debug/risc-v-rust-bare-metal -nographic
```

Sample output:

```
Hello, world!
Prime: 2
Prime: 3
Prime: 5
Prime: 7
Prime: 11
Prime: 13
Prime: 17
Prime: 19
```

## Article

This code is based of this article http://popovicu.com/posts/bare-metal-rust-risc-v-with-dynamic-memory
