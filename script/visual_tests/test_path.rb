#!/usr/bin/env ruby
# frozen_string_literal: true

require "clack"

def test(name)
  puts
  puts "\e[1;36m--- TEST: #{name} ---\e[0m"
  puts
  result = yield
  if Clack.cancel?(result)
    Clack.log.warning "Cancelled"
  else
    Clack.log.success "Result: #{result.inspect}"
  end
  sleep 0.3
end

Clack.intro "Path Prompt Edge Cases"

test("Basic path (files and directories)") do
  Clack.path(
    message: "Choose a file:",
    only_directories: false
  )
end

test("Directories only") do
  Clack.path(
    message: "Choose a directory:",
    only_directories: true
  )
end

test("Path with custom root") do
  Clack.path(
    message: "Browse from lib/:",
    root: "lib"
  )
end

test("Path with validation") do
  Clack.path(
    message: "Choose a Ruby file:",
    validate: ->(v) { "Must be a .rb file" unless v.end_with?(".rb") }
  )
end

Clack.outro "Path tests complete!"
