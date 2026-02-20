#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/validation.rb

require_relative "../lib/clack" # Or: require "clack" if installed as a gem

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

# Phone number with validation and custom transform
phone = Clack.text(
  message: "Phone number",
  validate: ->(v) { "Enter 10 digits" unless v.gsub(/\D/, "").length == 10 },
  transform: ->(v) {
    digits = v.gsub(/\D/, "")
    "(#{digits[0, 3]}) #{digits[3, 3]}-#{digits[6, 4]}"
  }
)
exit 0 if Clack.cancel?(phone)

# Username with transform (symbol shortcuts + custom)
handle = Clack.text(
  message: "Twitter handle",
  transform: Clack::Transformers.chain(:strip, :downcase, ->(v) { v.delete_prefix("@") })
)
exit 0 if Clack.cancel?(handle)

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
Clack.log.info "Phone: #{phone}"
Clack.log.info "Handle: @#{handle}"
Clack.log.info "Features: #{features.join(", ")}"

Clack.outro "Done!"
