# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    enable_coverage :branch

    # Exclude interactive/IO code that can't be unit tested
    add_filter "lib/clack/core/key_reader.rb"

    # Coverage groups for reporting
    add_group "Prompts", "lib/clack/prompts"
    add_group "Core", "lib/clack/core"
    add_group "Main", "lib/clack"

    # Minimum coverage for testable code (excluding demo methods)
    minimum_coverage line: 95, branch: 75
  end
end

require "clack"
require "stringio"

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  # Enable ANSI escape sequences for tests (cursor codes, etc.)
  config.before(:suite) do
    Clack::Core::Cursor.enabled = true
  end

  config.after(:suite) do
    Clack::Core::Cursor.enabled = nil
  end
end
