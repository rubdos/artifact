/*  rst: the requirements tracking tool made for developers
 * Copyright (C) 2016  Garrett Berg <@vitiral, vitiral@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the Lesser GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the Lesser GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * */
extern crate rst_app;
extern crate error_chain;
use std::io;
use std::env;
use std::process;

use rst_app::cmd;
fn main() {
    let rc = match cmd::cmd(&mut io::stdout(), env::args()) {
        Err(e) => {
        	use ::std::io::Write;
        	let stderr = &mut io::stderr();
        	let errmsg = "Error writing to stderr";

        	writeln!(stderr, "# error: {}", e).expect(errmsg);

        	for e in e.iter().skip(1) {
        	    writeln!(stderr, "## caused by: {}", e).expect(errmsg);
        	}

        	// The backtrace is not always generated. Try to run this example
        	// with `RUST_BACKTRACE=1`.
        	if let Some(backtrace) = e.backtrace() {
        	    writeln!(stderr, "backtrace: {:?}", backtrace).expect(errmsg);
        	}

            println!("ERROR: {}", e);
            1
        }
        Ok(()) => 0,
    };
    process::exit(rc)
}
