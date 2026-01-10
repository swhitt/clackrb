#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/clack"

phone = Clack.text(
  message: "Phone number",
  placeholder: "Enter 10 digits",
  validate: ->(v) { "Enter exactly 10 digits" unless v.gsub(/\D/, "").length == 10 },
  transform: ->(v) {
    digits = v.gsub(/\D/, "")
    "(#{digits[0, 3]}) #{digits[3, 3]}-#{digits[6, 4]}"
  }
)

exit 0 if Clack.cancel?(phone)

Clack.log.success "Formatted: #{phone}"
