#![no_std]
#![no_main]
#![feature(const_mut_refs)]

use core::arch::global_asm;
use core::panic::PanicInfo;
use core::ptr;
use talc::{ClaimOnOom, Span, Talc, Talck};

#[macro_use]
extern crate alloc;
use alloc::format;
use alloc::vec;
use alloc::vec::Vec;

global_asm!(include_str!("entry.s"));

static mut ARENA: [u8; 50000] = [0; 50000];

#[global_allocator]
static ALLOCATOR: Talck<spin::Mutex<()>, ClaimOnOom> =
    Talc::new(unsafe { ClaimOnOom::new(Span::from_array(&mut ARENA)) }).lock();

fn uart_print(message: &str) {
    const UART: *mut u8 = 0x10000000 as *mut u8;

    for c in message.chars() {
        unsafe {
            ptr::write_volatile(UART, c as u8);
        }
    }
}

#[no_mangle]
pub extern "C" fn main() -> ! {
    uart_print("Hello, world!\n");

    let mut i = 0;
    loop {
        let message = format!("Ticks: {}\n", prime);
        let temp_str = message.as_str();
        uart_print(temp_str);
        i += 1;
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    uart_print("Something went wrong.");
    loop {}
}
