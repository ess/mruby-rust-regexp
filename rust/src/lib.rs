#[macro_use]
extern crate mferuby;

#[macro_use]
extern crate regex;

use mferuby::sys;
use std::ffi::CString;
use std::mem;
use mferuby::libc::{c_int};

#[no_mangle]
#[allow(unused_variables)]
pub extern "C" fn mrb_rust_regex_valid(mrb: *mut sys::mrb_state, this: sys::mrb_value) -> sys::mrb_value {
  let mut pattern: sys::mrb_value = unsafe {mem::uninitialized()};

  unsafe {
    sys::mrb_get_args(mrb, cstr!("S"), &mut pattern);
  }

  let rust_pattern = mferuby::mruby_str_to_rust_string(pattern).unwrap();

  match regex::Regex::new(rust_pattern.as_str()) {
    Ok(r) => {
      unsafe {sys::mrb_true()}
    },
    Err(e) => {
      unsafe {sys::mrb_false()}
    }
  }
}

#[no_mangle]
#[allow(unused_variables)]
pub extern "C" fn mrb_rust_regex_escape(mrb: *mut sys::mrb_state, this: sys::mrb_value) -> sys::mrb_value {
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
#[allow(unused_variables)]
pub extern "C" fn mrb_rust_regex_match(mrb: *mut sys::mrb_state, this: sys::mrb_value) -> sys::mrb_value {
  let mut pattern: sys::mrb_value = unsafe {mem::uninitialized()};
  let mut input: sys::mrb_value = unsafe {mem::uninitialized()};
  //let mut ignore_case: bool;
  //let mut multi_line: bool;

  unsafe {
    //sys::mrb_get_args(mrb, cstr!("SSbb"), &mut pattern, &mut input, &mut ignore_case, &mut multi_line);
    sys::mrb_get_args(mrb, cstr!("SS"), &mut pattern, &mut input);

    let rpattern = mferuby::mruby_str_to_rust_string(pattern).unwrap();
    let rinput = mferuby::mruby_str_to_rust_string(input).unwrap();

    let builder = regex::RegexBuilder::new(rpattern.as_str());
    
    //if ignore_case {
    //  builder.case_insensitive(true);
    //}

    //if multi_line {
    //  builder.multi_line(true);
    //}

    let re = builder.build().unwrap();

    let retval = sys::mrb_ary_new(mrb);

    //let named_captures = sys::mrb_ary_new(mrb);

    if !re.is_match(rinput.as_str()) {
      // Go ahead and stop here. It's not a match, so there's nothing more
      // to do.
      return retval
    }

    match re.captures(rinput.as_str()) {
      Some(caps) => {
        for sub in caps.iter() {
          match sub {
            None => {
              let row = sys::mrb_ary_new(mrb);

              sys::mrb_ary_push(mrb, row, sys::nil());
              sys::mrb_ary_push(mrb, row, sys::nil());
              sys::mrb_ary_push(mrb, row, sys::nil());
              sys::mrb_ary_push(mrb, row, sys::nil());

              sys::mrb_ary_push(mrb, retval, row);

            },
            Some(sub) => {
              let row = sys::mrb_ary_new(mrb);

              sys::mrb_ary_push(mrb, row, sys::fixnum(sub.start() as c_int));
              sys::mrb_ary_push(mrb, row, sys::fixnum(sub.end() as c_int));
              sys::mrb_ary_push(mrb, row, sys::mrb_str_new_cstr(mrb, cstr!(sub.as_str())));
              sys::mrb_ary_push(mrb, row, sys::nil());

              sys::mrb_ary_push(mrb, retval, row);
            },
          }
        }

        for name in re.capture_names() {
          match name {
            Some(name) => {
              match caps.name(name) {
                Some(named) => {
                  let row = sys::mrb_ary_new(mrb);
                  sys::mrb_ary_push(mrb, row, sys::fixnum(named.start() as c_int));
                  sys::mrb_ary_push(mrb, row, sys::fixnum(named.end() as c_int));
                  sys::mrb_ary_push(mrb, row, sys::mrb_str_new_cstr(mrb, cstr!(named.as_str())));
                  sys::mrb_ary_push(mrb, row, sys::mrb_str_new_cstr(mrb, cstr!(name)));
                  sys::mrb_ary_push(mrb, retval, row);
                },
                None => {
                  let row = sys::mrb_ary_new(mrb);

                  sys::mrb_ary_push(mrb, row, sys::nil());
                  sys::mrb_ary_push(mrb, row, sys::nil());
                  sys::mrb_ary_push(mrb, row, sys::nil());
                  sys::mrb_ary_push(mrb, row, sys::mrb_str_new_cstr(mrb, cstr!(name)));

                  sys::mrb_ary_push(mrb, retval, row);

                },
              }
            },
            None => {},
          }
        }

      },
      None => {},
    }

    retval
  }

}

#[no_mangle]
pub extern "C" fn mrb_mruby_rust_regexp_gem_init(mrb: *mut sys::mrb_state) {
  unsafe {
    let rust_regexp_mod = sys::mrb_define_class(mrb, cstr!("RustRegexp"), sys::mrb_state_object_class(mrb));
    sys::mrb_define_class_method(mrb, rust_regexp_mod, cstr!("escape"), mrb_rust_regex_escape as sys::mrb_func_t, sys::MRB_ARGS_REQ(1));
    sys::mrb_define_class_method(mrb, rust_regexp_mod, cstr!("valid?"), mrb_rust_regex_valid as sys::mrb_func_t, sys::MRB_ARGS_REQ(1));
    sys::mrb_define_class_method(mrb, rust_regexp_mod, cstr!("get_submatches"), mrb_rust_regex_match as sys::mrb_func_t, sys::MRB_ARGS_REQ(2));
  }
}

#[no_mangle]
#[allow(unused_variables)]
pub extern "C" fn mrb_mruby_rust_regexp_gem_final(mrb: *mut sys::mrb_state){
}
