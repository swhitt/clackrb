#!/usr/bin/env ruby
require_relative "../../lib/clack"

Clack.select(
  message: "Choose a database",
  options: [
    {value: "pg", label: "PostgreSQL", hint: "recommended"},
    {value: "mysql", label: "MySQL"},
    {value: "sqlite", label: "SQLite"}
  ]
)
