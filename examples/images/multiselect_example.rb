#!/usr/bin/env ruby
require_relative "../../lib/clack"

Clack.multiselect(
  message: "Select features to install",
  options: [
    {value: "api", label: "API Mode"},
    {value: "auth", label: "Authentication"},
    {value: "jobs", label: "Background Jobs"}
  ]
)
