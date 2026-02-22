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

Clack.intro "Miscellaneous Widget Tests"

test("Log methods") do
  Clack.log.info "This is info"
  Clack.log.success "This is success"
  Clack.log.warn "This is a warning"
  Clack.log.error "This is an error"
  Clack.log.step "This is a step"
  :ok
end

test("Note (no title)") do
  Clack.note("This is an important note.\nIt can span multiple lines.")
  :ok
end

test("Note (with title)") do
  Clack.note("Configuration saved successfully.\nRestart to apply changes.", title: "Notice")
  :ok
end

test("Box") do
  Clack.box("Hello from Clack!", title: "Welcome")
  :ok
end

test("Box centered") do
  Clack.box("Centered content\nLine two\nLine three", title: "Centered", content_align: :center)
  :ok
end

test("Group (multiple prompts in sequence)") do
  result = Clack.group { |g|
    g.prompt(:name) { Clack.text(message: "Your name:") }
    g.prompt(:confirm) { Clack.confirm(message: "Ready?") }
  }
  result
end

test("Handle cancel helper") do
  val = Clack.text(message: "Type something or press Escape:")
  if Clack.handle_cancel(val, "User cancelled the input")
    :cancelled
  else
    val
  end
end

Clack.outro "Miscellaneous tests complete!"
