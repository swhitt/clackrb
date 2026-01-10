#!/usr/bin/env ruby
require_relative "../../lib/clack"

Clack.text(
  message: "What is your project named?",
  placeholder: "my-project"
)
