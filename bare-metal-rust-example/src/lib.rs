#![no_std]
#![no_main]

use core::alloc::{GlobalAlloc, Layout};
use core::ffi::c_char;
use core::ffi::c_void;
use core::fmt::Write;
use core::ptr;
extern crate alloc;
use alloc::vec::Vec;
unsafe extern "C" {
    fn printk(fmt: *const core::ffi::c_char, ...) -> core::ffi::c_int;
    fn rtems_panic(fmt: *const core::ffi::c_char, ...) -> !;
    fn rtems_shutdown_executive(fatal_code: u32);
    fn malloc(size: usize) -> *mut c_void;
    fn realloc(ptr: *mut c_void, size: usize) -> *mut c_void;
    fn free(ptr: *mut c_void);
}
/// Define a Rust Global Allocator that uses RTEMS memory allocation

struct RtemsAllocator;

unsafe impl GlobalAlloc for RtemsAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        let ptr = unsafe { malloc(layout.size()) } as *mut u8;
        if ptr.is_null() {
            ptr::null_mut() // Return null if allocation fails
        } else {
            ptr
        }
    }

    unsafe fn dealloc(&self, ptr: *mut u8, _layout: Layout) {
        unsafe { free(ptr as *mut c_void) };
    }

    unsafe fn realloc(&self, ptr: *mut u8, _layout: Layout, new_size: usize) -> *mut u8 {
        let new_ptr = unsafe { realloc(ptr as *mut c_void, new_size) as *mut u8 };
        if new_ptr.is_null() {
            ptr::null_mut() // Return null if reallocation fails
        } else {
            new_ptr
        }
    }
}

// Set RTEMS allocator as the global allocator
#[global_allocator]
static GLOBAL: RtemsAllocator = RtemsAllocator;

/// Write text to the console using RTEMS `printk()` function
struct Console;

impl core::fmt::Write for Console {
    fn write_str(&mut self, message: &str) -> core::fmt::Result {
        const FORMAT_STR: &core::ffi::CStr = {
            let Ok(s) = core::ffi::CStr::from_bytes_with_nul(b"%.*s\0") else {
                panic!()
            };
            s
        };
        if message.len() != 0 {
            unsafe {
                printk(
                    FORMAT_STR.as_ptr(),
                    message.len() as core::ffi::c_int,
                    message.as_ptr(),
                );
            }
        }
        Ok(())
    }
}

/// Our `Init()` calls `rust_main()` and handles errors
#[unsafe(no_mangle)]
pub extern "C" fn Init() {
    if let Err(e) = rust_main() {
        panic!("Main returned {:?}", e);
    }
    unsafe {
        rtems_shutdown_executive(0);
    }
}

/// This is the main function of this program
fn rust_main() -> Result<(), core::fmt::Error> {
    let mut console = Console;
    let mut v = Vec::new();
    v.push(1);
    v.push(2);
    for a in v {
        writeln!(console, "Hello from Rust {}", a)?;
    }
    Ok(())
}

/// Handle panic by forwarding it to the `rtems_panic()` handler
#[panic_handler]
fn panic(panic: &core::panic::PanicInfo) -> ! {
    // The panic message can only be reached from libcore in unstable
    // (i.e. nightly builds). Print at least the location raising the panic.
    // See https://www.ralfj.de/blog/2019/11/25/how-to-panic-in-rust.html
    if let Some(location) = panic.location() {
        const FORMAT_STR: *const c_char = {
            const BYTES: &[u8] = b"Panic occurred at %.*s:%d:%d\n\0";
            BYTES.as_ptr().cast()
        };
        if location.file().len() != 0 {
            unsafe {
                rtems_panic(
                    FORMAT_STR,
                    location.file().len() as core::ffi::c_int,
                    location.file().as_ptr(),
                    location.line() as core::ffi::c_int,
                    location.column() as core::ffi::c_int,
                );
            }
        }
    }

    // If there is no location, fall back to the basic.
    let message = "Panic occured!";
    const FORMAT_PTR: *const c_char = {
        const BYTES: &[u8] = b"%.*s\n\0";
        BYTES.as_ptr().cast()
    };
    unsafe {
        rtems_panic(
            FORMAT_PTR,
            message.len() as core::ffi::c_int,
            message.as_ptr(),
        );
    }
}
