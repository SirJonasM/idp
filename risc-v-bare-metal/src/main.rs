#![no_std]
#![no_main]

use core::arch::global_asm;
use core::panic::PanicInfo;
use core::ptr;

global_asm!(include_str!("entry.s"));

const UART: *mut u8 = 0x10000000 as *mut u8;
fn uart_print(message: &str) {
    for c in message.chars() {
        unsafe {
            ptr::write_volatile(UART, c as u8);
        }
    }
}

#[no_mangle]
pub extern "C" fn main() -> ! {
    loop {
        uart_print("Hello, world!\n");
        for _ in 0..5000000 {}
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    uart_print("Something went wrong.");
    loop {}
}
