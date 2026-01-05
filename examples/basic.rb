#!/usr/bin/env ruby
require_relative "../lib/clack"

Clack.intro "basic-example"

name = Clack.text(message: "What is your name?", placeholder: "Anonymous")
exit 0 if Clack.cancel?(name)

Clack.log.success "Hello, #{name}!"

Clack.outro "Goodbye!"
