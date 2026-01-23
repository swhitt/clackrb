#!/usr/bin/env ruby
# frozen_string_literal: true

# Full demo showcasing Clack Ruby features
# Run with: ruby examples/full_demo.rb

require_relative "../lib/clack"

Clack.intro "create-service"

# Text input
name = Clack.text(
  message: "Service name:",
  placeholder: "order-service"
)
exit 1 if Clack.handle_cancel(name)

# Password input (masked)
token = Clack.password(
  message: "GitHub token:",
  mask: "•"
)
exit 1 if Clack.handle_cancel(token)

# Confirm
use_openapi = Clack.confirm(
  message: "Generate OpenAPI spec?",
  initial_value: true
)
exit 1 if Clack.handle_cancel(use_openapi)

# Select (single choice)
language = Clack.select(
  message: "Language:",
  options: [
    {value: "java", label: "Java 21", hint: "Spring Boot 3"},
    {value: "python", label: "Python 3.12", hint: "FastAPI"},
    {value: "go", label: "Go 1.22", hint: "chi"},
    {value: "node", label: "Node.js 22", hint: "Fastify"}
  ]
)
exit 1 if Clack.handle_cancel(language)

# Multiselect
integrations = Clack.multiselect(
  message: "Integrations:",
  options: [
    {value: "postgres", label: "PostgreSQL"},
    {value: "redis", label: "Redis"},
    {value: "kafka", label: "Kafka"},
    {value: "s3", label: "S3"}
  ],
  required: false
)
exit 1 if Clack.handle_cancel(integrations)

# Progress bar
prog = Clack.progress(total: 100, message: "Scaffolding...")
prog.start
5.times do
  sleep 0.4
  prog.advance(20)
end
prog.stop("Done")

# Spinner
s = Clack.spinner
s.start "Installing dependencies..."
sleep 0.8
s.message "Configuring CI..."
sleep 0.6
s.stop "Ready"

# Summary
Clack.log.step "Service: #{name}"
Clack.log.step "Stack: #{language}"
Clack.log.step "Integrations: #{integrations.join(", ")}" unless integrations.empty?

Clack.note <<~MSG, title: "Next steps"
  cd #{name}
  make dev
MSG

Clack.outro "Ship it"
