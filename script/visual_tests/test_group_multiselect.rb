#!/usr/bin/env ruby
# frozen_string_literal: true

require "clack"

def test(name)
  puts
  puts "\e[1;36m--- TEST: #{name} ---\e[0m"
  puts
  result = yield
  if Clack.cancel?(result)
    Clack.log.warning "Cancelled"
  else
    display = result.is_a?(Array) ? result.join(", ") : result.inspect
    Clack.log.success "Result: #{display}"
  end
  sleep 0.3
end

Clack.intro "Group Multiselect Edge Cases"

test("Group multiselect with selectable groups") do
  Clack.group_multiselect(
    message: "Select stack components:",
    selectable_groups: true,
    required: true,
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
          {value: "rails", label: "Rails"},
          {value: "express", label: "Express"},
          {value: "django", label: "Django"}
        ]
      }
    ]
  )
end

test("Group multiselect WITHOUT selectable groups") do
  Clack.group_multiselect(
    message: "Select items (group headers not selectable):",
    selectable_groups: false,
    required: false,
    options: [
      {
        label: "Fruits",
        options: [{value: "apple", label: "Apple"}, {value: "banana", label: "Banana"}]
      },
      {
        label: "Vegetables",
        options: [{value: "carrot", label: "Carrot"}, {value: "broccoli", label: "Broccoli"}]
      }
    ]
  )
end

test("Group multiselect with initial values") do
  Clack.group_multiselect(
    message: "Pre-selected items:",
    selectable_groups: true,
    required: false,
    initial_values: ["docker", "postgres"],
    options: [
      {
        label: "Database",
        options: [
          {value: "postgres", label: "PostgreSQL"},
          {value: "mysql", label: "MySQL"},
          {value: "sqlite", label: "SQLite"}
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
end

test("Group multiselect with group_spacing") do
  Clack.group_multiselect(
    message: "With extra spacing between groups:",
    selectable_groups: true,
    group_spacing: 1,
    required: false,
    options: [
      {
        label: "Group A",
        options: [{value: "a1", label: "Item A1"}, {value: "a2", label: "Item A2"}]
      },
      {
        label: "Group B",
        options: [{value: "b1", label: "Item B1"}, {value: "b2", label: "Item B2"}]
      },
      {
        label: "Group C",
        options: [{value: "c1", label: "Item C1"}, {value: "c2", label: "Item C2"}]
      }
    ]
  )
end

Clack.outro "Group multiselect tests complete!"
