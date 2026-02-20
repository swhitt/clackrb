#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script showcasing all Clack Ruby prompts
# Run with: ruby examples/demo.rb

require_relative "../lib/clack" # Or: require "clack" if installed as a gem

def run_demo
  Clack.intro "clack-demo"

  result = Clack.group(on_cancel: ->(_) { Clack.cancel("Operation cancelled.") }) do |g|
    g.prompt(:name) do
      Clack.text(
        message: "What is your project named?",
        placeholder: "my-app",
        validate: ->(v) { "Project name is required" if v.to_s.strip.empty? }
      )
    end

    g.prompt(:directory) do |r|
      Clack.text(
        message: "Where should we create your project?",
        initial_value: "./#{r[:name]}"
      )
    end

    g.prompt(:template) do
      Clack.select(
        message: "Which template would you like to use?",
        options: [
          {value: "default", label: "Default", hint: "recommended"},
          {value: "minimal", label: "Minimal", hint: "bare bones"},
          {value: "api", label: "API Only", hint: "no frontend"},
          {value: "full", label: "Full Stack", hint: "everything included"}
        ]
      )
    end

    g.prompt(:typescript) do
      Clack.confirm(
        message: "Would you like to use TypeScript?",
        initial_value: true
      )
    end

    g.prompt(:features) do
      Clack.multiselect(
        message: "Which features would you like to include?",
        options: [
          {value: "eslint", label: "ESLint", hint: "code linting"},
          {value: "prettier", label: "Prettier", hint: "code formatting"},
          {value: "tailwind", label: "Tailwind CSS", hint: "utility-first CSS"},
          {value: "docker", label: "Docker", hint: "containerization"},
          {value: "ci", label: "GitHub Actions", hint: "CI/CD pipeline"}
        ],
        initial_values: %w[eslint prettier],
        required: false
      )
    end

    g.prompt(:package_manager) do
      Clack.select(
        message: "Which package manager do you prefer?",
        options: [
          {value: "npm", label: "npm"},
          {value: "yarn", label: "yarn"},
          {value: "pnpm", label: "pnpm", hint: "recommended"},
          {value: "bun", label: "bun", hint: "fast"}
        ],
        initial_value: "pnpm"
      )
    end
  end

  return if Clack.handle_cancel(result)

  # Autocomplete prompt
  color = Clack.autocomplete(
    message: "Pick a theme color:",
    options: %w[red orange yellow green blue indigo violet pink cyan magenta]
  )
  return if Clack.handle_cancel(color)

  # Select key prompt (quick keyboard shortcuts)
  action = Clack.select_key(
    message: "What would you like to do first?",
    options: [
      {value: "dev", label: "Start dev server", key: "d"},
      {value: "build", label: "Build for production", key: "b"},
      {value: "test", label: "Run tests", key: "t"}
    ]
  )
  return if Clack.handle_cancel(action)

  # Path prompt
  config_path = Clack.path(
    message: "Select config directory:",
    only_directories: true
  )
  return if Clack.handle_cancel(config_path)

  # Group multiselect
  stack = Clack.group_multiselect(
    message: "Select additional integrations:",
    options: [
      {
        label: "Frontend",
        options: [
          {value: "react", label: "React"},
          {value: "vue", label: "Vue"},
          {value: "svelte", label: "Svelte"}
        ]
      },
      {
        label: "Backend",
        options: [
          {value: "express", label: "Express"},
          {value: "fastify", label: "Fastify"},
          {value: "hono", label: "Hono"}
        ]
      },
      {
        label: "Database",
        options: [
          {value: "postgres", label: "PostgreSQL"},
          {value: "mysql", label: "MySQL"},
          {value: "sqlite", label: "SQLite"}
        ]
      }
    ],
    required: false
  )
  return if Clack.handle_cancel(stack)

  # Progress bar
  prog = Clack.progress(total: 100, message: "Downloading assets...")
  prog.start
  20.times do
    sleep 0.03
    prog.advance(5)
  end
  prog.stop("Assets downloaded!")

  # Tasks
  Clack.tasks(tasks: [
    {title: "Validating configuration", task: -> { sleep 0.3 }},
    {title: "Generating types", task: -> { sleep 0.4 }},
    {title: "Compiling assets", task: -> { sleep 0.3 }}
  ])

  # Spinner
  s = Clack.spinner
  s.start "Installing dependencies via #{result[:package_manager]}..."
  sleep 1.0
  s.message "Configuring #{result[:template]} template..."
  sleep 0.6
  s.stop "Project created successfully!"

  # Summary
  Clack.log.step "Project: #{result[:name]}"
  Clack.log.step "Directory: #{result[:directory]}"
  Clack.log.step "Template: #{result[:template]}"
  Clack.log.step "TypeScript: #{result[:typescript] ? "Yes" : "No"}"
  Clack.log.step "Features: #{result[:features].join(", ")}" unless result[:features].empty?
  Clack.log.step "Color: #{color}"
  Clack.log.step "Action: #{action}"
  Clack.log.step "Config: #{config_path}"
  Clack.log.step "Stack: #{stack.join(", ")}" unless stack.empty?

  Clack.note <<~MSG, title: "Next steps"
    cd #{result[:directory]}
    #{result[:package_manager]} run dev
  MSG

  Clack.outro "Happy coding!"
end

run_demo if __FILE__ == $PROGRAM_NAME
