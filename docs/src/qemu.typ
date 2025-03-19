= QEMU
QEMU is an open-source machine emulator and virtualizer that can simulate a wide range of CPU architectures, including RISC-V. By running your program on QEMU, you can develop and test embedded applications without needing the actual hardware. For a RISC-V 32-bit setup (e.g., riscv32i), you typically invoke QEMU with a command like:
```sh
qemu-system-riscv32 \
    -nographic \
    -machine virt \
    -kernel path/to/your_program.elf
```
Here, -machine virt selects the generic RISC-V “virt” machine, while -nographic routes I/O through the terminal rather than a graphical console. You can then observe your program’s output and interact with it as though it were running on physical hardware. This approach is especially helpful during early development, debugging, and continuous integration on embedded targets.
