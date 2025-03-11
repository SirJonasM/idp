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
struct PrimeGenerator {
    primes: Vec<usize>,
    sieve: Vec<bool>,
    limit: usize,
}

impl PrimeGenerator {
    fn new() -> Self {
        Self {
            primes: Vec::new(),
            sieve: vec![true; 10], // Initial small sieve
            limit: 10,
        }
    }

    fn expand_sieve(&mut self) {
        self.limit *= 2; // Double the sieve size
        self.sieve = vec![true; self.limit];
        self.sieve[0] = false;
        self.sieve[1] = false;

        for &p in &self.primes {
            let mut multiple = p * p;
            while multiple < self.limit {
                self.sieve[multiple] = false;
                multiple += p;
            }
        }
    }

    fn next_prime(&mut self) -> usize {
        loop {
            for i in (self.primes.last().copied().unwrap_or(1) + 1)..self.limit {
                if self.sieve[i] {
                    self.primes.push(i);
                    let mut multiple = i * i;
                    while multiple < self.limit {
                        self.sieve[multiple] = false;
                        multiple += i;
                    }
                    return i;
                }
            }
            self.expand_sieve();
        }
    }
}

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

    let mut prime_generator = PrimeGenerator::new();
    loop {
        let prime = prime_generator.next_prime();
        let message = format!("Ticks: {}\n", prime);
        let temp_str = message.as_str();

        uart_print(temp_str);
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    uart_print("Something went wrong.");
    loop {}
}

