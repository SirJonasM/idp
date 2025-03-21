= Milestone Plan
1. Technical Onboarding (2 Weeks)
    - Familiarization with QEMU, RTEMS, and RISC-V
    - Understanding toolchain configurations, BSP setup, and target hardware requirements
2. Application on Hardware (4 Weeks)
    - Running a basic "Hello World" program on the hardware
    - Implementing a register interface via the FPGA-APB bus
3. Performance Comparisons (1 Week)
    - Comparing assembly code in C and Rust
    - Evaluating a minimal functional program in both C and Rust (memory usage & performance analysis)
4. Abstraction Layer Development (2 Weeks)
    - Translating C code into a Rust-based abstraction layer
    - Abstracting RTEMS functionalities (multi-tasking, timers, etc.)
    - Writing documentation for the abstraction layer
5. Rust Coding Guidelines (1 Week)
    - Documenting best practices for Rust vs. C in terms of quality and performance (building on findings from Step 3)
6. (Potential Future Step: Rewriting application software modules in Rust)
