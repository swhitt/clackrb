# frozen_string_literal: true

require_relative "lib/clack/version"

Gem::Specification.new do |spec|
  spec.name = "clack"
  spec.version = Clack::VERSION
  spec.authors = ["Steve Whittaker"]
  spec.email = ["swhitt@gmail.com"]

  spec.summary = "Beautiful, minimal CLI prompts"
  spec.description = "Ruby port of Clack — effortlessly build beautiful command-line apps with the modern, minimal aesthetic popularized by Vercel and Astro."
  spec.homepage = "https://github.com/swhitt/clackrb"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*", "examples/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"] -
    Dir["examples/split_cast.rb"]
  spec.bindir = "exe"
  spec.executables = ["clack-demo"]
  spec.require_paths = ["lib"]

  # Zero runtime dependencies
end
