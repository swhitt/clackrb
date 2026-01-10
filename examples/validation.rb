#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/clack"

Clack.intro "validation-demo"

# Required field (hard error)
name = Clack.text(
  message: "Username (required)",
  validate: ->(v) { "Username is required" if v.to_s.strip.empty? }
)
exit 0 if Clack.cancel?(name)

# Password with both error and warning
# - Empty: hard error (blocks submission)
# - Short: warning (can confirm to proceed)
password = Clack.password(
  message: "Password",
  validate: lambda { |v|
    return "Password is required" if v.empty?

    Clack.warning("Weak password - press Enter to use anyway") if v.length < 8
  }
)
exit 0 if Clack.cancel?(password)

# Email with format validation
email = Clack.text(
  message: "Email address",
  validate: lambda { |v|
    return "Email is required" if v.to_s.strip.empty?
    return "Invalid email format" unless v.to_s.include?("@")

    nil
  }
)
exit 0 if Clack.cancel?(email)

# Output file with overwrite warning using built-in validator
output = Clack.text(
  message: "Output file",
  placeholder: "output.json",
  default_value: "output.json",
  validate: Clack::Validators.file_exists_warning
)
exit 0 if Clack.cancel?(output)

# Using as_warning to convert any validator to a soft warning
bio = Clack.text(
  message: "Bio (optional)",
  validate: Clack::Validators.as_warning(
    Clack::Validators.max_length(50, "Bio is quite long")
  )
)
exit 0 if Clack.cancel?(bio)

Clack.log.success "All validations passed!"
Clack.log.info "Username: #{name}"
Clack.log.info "Email: #{email}"
Clack.log.info "Output: #{output}"

Clack.outro "Done!"
