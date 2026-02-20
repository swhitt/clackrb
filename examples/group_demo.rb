#!/usr/bin/env ruby
# frozen_string_literal: true

# Demonstrates Clack.group and group_multiselect
# Run with: ruby examples/group_demo.rb

require_relative "../lib/clack" # Or: require "clack" if installed as a gem

Clack.intro "group-demo"

# Prompt group with on_cancel handler
result = Clack.group(
  on_cancel: ->(partial) {
    Clack.cancel "Cancelled (collected: #{partial.keys.select { |k| partial[k] != :cancelled }.join(", ")})"
    exit 0
  }
) do |g|
  g.prompt(:name) { Clack.text(message: "Project name:", placeholder: "my-project") }

  g.prompt(:visibility) do |results|
    Clack.select(
      message: "Visibility for #{results[:name]}?",
      options: [
        {value: "public", label: "Public", hint: "visible to everyone"},
        {value: "private", label: "Private", hint: "invite only"}
      ]
    )
  end

  g.prompt(:confirm) do |results|
    Clack.confirm(message: "Create #{results[:visibility]} project '#{results[:name]}'?")
  end
end

unless result[:confirm]
  Clack.outro "Project creation skipped."
  exit 0
end

Clack.log.success "Project: #{result[:name]} (#{result[:visibility]})"

# Group multiselect with selectable group headers and spacing
stack = Clack.group_multiselect(
  message: "Select stack components:",
  selectable_groups: true,
  group_spacing: 1,
  required: true,
  options: [
    {
      label: "Frontend",
      options: [
        {value: "react", label: "React"},
        {value: "tailwind", label: "Tailwind CSS"},
        {value: "typescript", label: "TypeScript"}
      ]
    },
    {
      label: "Backend",
      options: [
        {value: "rails", label: "Ruby on Rails"},
        {value: "sidekiq", label: "Sidekiq"},
        {value: "graphql", label: "GraphQL"}
      ]
    },
    {
      label: "Infrastructure",
      options: [
        {value: "docker", label: "Docker"},
        {value: "k8s", label: "Kubernetes"},
        {value: "terraform", label: "Terraform"}
      ]
    }
  ]
)
exit 0 if Clack.cancel?(stack)

Clack.log.step "Stack: #{stack.join(", ")}"

Clack.outro "Done!"
