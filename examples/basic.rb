#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/basic.rb

require_relative "../lib/clack" # Or: require "clack" if installed as a gem

Clack.intro "basic-example"

name = Clack.text(message: "What is your name?", placeholder: "Anonymous")
exit 0 if Clack.cancel?(name)

Clack.log.success "Hello, #{name}!"

Clack.outro "Goodbye!"
