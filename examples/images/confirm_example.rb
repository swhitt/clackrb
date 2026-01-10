#!/usr/bin/env ruby
require_relative "../../lib/clack"

Clack.confirm(
  message: "Deploy to production?",
  active: "Yes, ship it!",
  inactive: "No, abort"
)
