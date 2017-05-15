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

  let escaped = regex::escape(&rust_unescaped);

  unsafe {
    sys::mrb_str_new_cstr(mrb, cstr!(escaped))
  }
}

#[no_mangle]
pub extern "C" fn mrb_rust_regex_match(mrb: *mut sys::mrb_state, this: sys::mrb_value) -> sys::mrb_value {
  let mut pattern: sys::mrb_value = unsafe {mem::uninitialized()};
  let mut input: sys::mrb_value = unsafe {mem::uninitialized()};

  unsafe {
    sys::mrb_get_args(mrb, cstr!("SS"), &mut pattern, &mut input);
  }

  println!("matching {} against {}", mferuby::mruby_str_to_rust_string(input).unwrap(), mferuby::mruby_str_to_rust_string(pattern).unwrap());

  unsafe {sys::nil()}
}

#[no_mangle]
pub extern "C" fn mrb_mruby_rust_regexp_gem_init(mrb: *mut sys::mrb_state) {
  unsafe {
    let rust_regexp_mod = sys::mrb_define_class(mrb, cstr!("RustRegexp"), sys::mrb_state_object_class(mrb));
    sys::mrb_define_class_method(mrb, rust_regexp_mod, cstr!("escape"), mrb_rust_regex_escape as sys::mrb_func_t, sys::MRB_ARGS_REQ(1));
    sys::mrb_define_class_method(mrb, rust_regexp_mod, cstr!("match"), mrb_rust_regex_match as sys::mrb_func_t, sys::MRB_ARGS_REQ(2));
  }
}

#[no_mangle]
#[allow(unused_variables)]
pub extern "C" fn mrb_mruby_rust_regexp_gem_final(mrb: *mut sys::mrb_state){
}
