#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/clack"

Clack.intro "validation-demo"

# Required field
name = Clack.text(
  message: "Username (required)",
  validate: ->(v) { "Username is required" if v.to_s.strip.empty? }
)
exit 0 if Clack.cancel?(name)

# Length validation
password = Clack.password(
  message: "Password (min 8 chars)",
  validate: ->(v) { "Password must be at least 8 characters" if v.to_s.length < 8 }
)
exit 0 if Clack.cancel?(password)

# Format validation
email = Clack.text(
  message: "Email address",
  validate: lambda { |v|
    return "Email is required" if v.to_s.strip.empty?
    return "Invalid email format" unless v.to_s.include?("@")

    nil
  }
)
exit 0 if Clack.cancel?(email)

# Multiselect required
features = Clack.multiselect(
  message: "Select at least one feature",
  options: [
    {value: "a", label: "Feature A"},
    {value: "b", label: "Feature B"},
    {value: "c", label: "Feature C"}
  ],
  required: true # Built-in validation
)
exit 0 if Clack.cancel?(features)

Clack.log.success "All validations passed!"
Clack.log.info "Username: #{name}"
Clack.log.info "Email: #{email}"
Clack.log.info "Features: #{features.join(", ")}"

Clack.outro "Done!"
