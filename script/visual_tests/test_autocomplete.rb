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
    Clack.log.success "Result: #{result.inspect}"
  end
  sleep 0.3
end

Clack.intro "Autocomplete Prompt Edge Cases"

test("Basic autocomplete") do
  Clack.autocomplete(
    message: "Pick a license:",
    placeholder: "Type to search...",
    options: [
      {value: "mit", label: "MIT", hint: "permissive"},
      {value: "apache2", label: "Apache 2.0", hint: "permissive"},
      {value: "gpl3", label: "GPL 3.0", hint: "copyleft"},
      {value: "agpl3", label: "AGPL 3.0", hint: "copyleft"},
      {value: "bsd2", label: "BSD 2-Clause"},
      {value: "bsd3", label: "BSD 3-Clause"},
      {value: "mpl2", label: "MPL 2.0"},
      {value: "unlicense", label: "Unlicense", hint: "public domain"}
    ]
  )
end

test("Autocomplete with many options (scroll test)") do
  Clack.autocomplete(
    message: "Choose a country:",
    placeholder: "Start typing...",
    max_items: 5,
    options: %w[
      Afghanistan Albania Algeria Argentina Australia Austria
      Belgium Brazil Canada Chile China Colombia Croatia
      Denmark Egypt Finland France Germany Greece
      Hungary Iceland India Indonesia Iran Iraq Ireland Italy
      Japan Kenya Latvia Lithuania Mexico Morocco
      Netherlands Norway Pakistan Peru Poland Portugal
      Romania Russia Spain Sweden Switzerland
      Thailand Turkey Ukraine UnitedKingdom UnitedStates Vietnam
    ]
  )
end

test("Autocomplete with no match scenario") do
  Clack.autocomplete(
    message: "Find a gem (try typing 'zzz'):",
    placeholder: "Type to filter...",
    options: %w[rails sinatra hanami roda grape padrino]
  )
end

test("Autocomplete with string options") do
  Clack.autocomplete(
    message: "Pick a color:",
    options: %w[Red Orange Yellow Green Blue Indigo Violet]
  )
end

test("Autocomplete with custom filter") do
  Clack.autocomplete(
    message: "Exact prefix match only:",
    placeholder: "Type exact prefix...",
    filter: ->(opt, query) { opt[:label].downcase.start_with?(query.downcase) },
    options: %w[Apple Apricot Avocado Banana Blueberry Cherry]
  )
end

Clack.outro "Autocomplete tests complete!"
