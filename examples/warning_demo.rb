#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo specifically showcasing validation warnings
# Warnings are "soft" validation failures that users can confirm past
# Run with: ruby examples/warning_demo.rb

require_relative "../lib/clack"

Clack.intro "Validation Warnings"

# 1. Password with entropy warning
# Must be 8+ chars, but common patterns trigger a warning
password = Clack.password(
  message: "Create a password",
  validate: lambda { |v|
    return "Password must be at least 8 characters" if v.length < 8
    return "Password must include a number" unless v.match?(/\d/)

    # Warn on low entropy patterns
    if v.match?(/^[a-z]+\d+$/i) || v.match?(/password/i) || v.match?(/^(.)\1+/)
      Clack.warning("This password may be easy to guess")
    end
  }
)
exit 0 if Clack.cancel?(password)

# 2. Simple select - no validation, just works
environment = Clack.select(
  message: "Target environment",
  options: [
    {value: "development", label: "Development"},
    {value: "staging", label: "Staging"},
    {value: "production", label: "Production"}
  ]
)
exit 0 if Clack.cancel?(environment)

# 3. File output with overwrite warning
output_file = Clack.text(
  message: "Output file",
  default_value: "README.md",
  validate: Clack::Validators.file_exists_warning("File already exists. Overwrite?")
)
exit 0 if Clack.cancel?(output_file)

# 4. Multiselect - no validation needed
features = Clack.multiselect(
  message: "Enable features",
  options: [
    {value: "logging", label: "Logging"},
    {value: "metrics", label: "Metrics"},
    {value: "tracing", label: "Tracing"}
  ],
  required: false
)
exit 0 if Clack.cancel?(features)

# 5. Username with case warning
username = Clack.text(
  message: "Username",
  validate: lambda { |v|
    return "Username is required" if v.strip.empty?
    return "Username cannot contain spaces" if v.include?(" ")

    Clack.warning("Lowercase recommended for compatibility") if v != v.downcase
  }
)
exit 0 if Clack.cancel?(username)

Clack.log.success "Configuration saved"
Clack.log.step "Environment: #{environment}"
Clack.log.step "Output: #{output_file}"
Clack.log.step "Features: #{features.empty? ? "(none)" : features.join(", ")}"
Clack.log.step "Username: #{username}"

Clack.outro "Setup complete"
