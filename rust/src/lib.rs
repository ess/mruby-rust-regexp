#[macro_use]
extern crate mferuby;

#[macro_use]
extern crate regex;

use mferuby::sys;
use std::ffi::CString;
use std::mem;

#[no_mangle]
pub extern "C" fn mrb_rust_regex_escape(mrb: *mut sys::mrb_state, selfie: sys::mrb_value) -> sys::mrb_value {
  let mut unescaped: sys::mrb_value = unsafe {mem::uninitialized()};

  unsafe {
    sys::mrb_get_args(mrb, cstr!("S"), &mut unescaped);
  }

  let rust_unescaped = mferuby::mruby_str_to_rust_string(unescaped).unwrap();

  let escaped = cstr!(regex::escape(&rust_unescaped));

  println!("Escaped {} -> {}", rust_unescaped, escaped)

  unsafe {
    sys::mrb_str_new_cstr(mrb, cstr!(regex::escape(&rust_unescaped)))
  }
}

#[no_mangle]
pub extern "C" fn mrb_mruby_rust_regexp_gem_init(mrb: *mut sys::mrb_state) {
  unsafe {
    let rust_regexp_mod = sys::mrb_define_class(mrb, cstr!("RustRegexp"), sys::mrb_state_object_class(mrb));
    sys::mrb_define_class_method(mrb, rust_regexp_mod, cstr!("escape"), regex::escape as sys::mrb_func_t, sys::MRB_ARGS_REQ(1));
  }
}

#[no_mangle]
#[allow(unused_variables)]
pub extern "C" fn mrb_mruby_rust_regexp_gem_final(mrb: *mut sys::mrb_state){
}
