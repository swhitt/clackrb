# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Clack::Environment do
  before do
    described_class.reset!
  end

  describe ".windows?" do
    it "returns boolean based on platform" do
      # On macOS/Linux this will be falsy, on Windows it will be truthy
      result = described_class.windows?
      expect([true, false, nil]).to include(result)
    end
  end

  describe ".ci?" do
    before do
      # Store original env vars
      @original_ci = ENV["CI"]
      @original_github = ENV["GITHUB_ACTIONS"]
    end

    after do
      # Restore original env vars
      ENV["CI"] = @original_ci
      ENV.delete("GITHUB_ACTIONS") unless @original_github
      described_class.reset!
    end

    it "detects CI=true" do
      ENV["CI"] = "true"
      described_class.reset!
      expect(described_class.ci?).to be true
    end

    it "detects GITHUB_ACTIONS" do
      ENV.delete("CI")
      ENV["GITHUB_ACTIONS"] = "true"
      described_class.reset!
      expect(described_class.ci?).to be true
    end

    it "returns false when no CI env vars" do
      %w[CI CONTINUOUS_INTEGRATION BUILD_NUMBER GITHUB_ACTIONS GITLAB_CI CIRCLECI TRAVIS JENKINS_URL TEAMCITY_VERSION BUILDKITE].each do |var|
        ENV.delete(var)
      end
      described_class.reset!
      expect(described_class.ci?).to be false
    end
  end

  describe ".tty?" do
    it "returns true for TTY output" do
      output = double("tty_output", tty?: true)
      expect(described_class.tty?(output)).to be true
    end

    it "returns false for non-TTY output" do
      output = StringIO.new
      expect(described_class.tty?(output)).to be false
    end

    it "returns false for output without tty? method" do
      output = Object.new
      expect(described_class.tty?(output)).to be false
    end
  end

  describe ".dumb_terminal?" do
    before { @original_term = ENV["TERM"] }
    after { ENV["TERM"] = @original_term }

    it "returns true when TERM=dumb" do
      ENV["TERM"] = "dumb"
      expect(described_class.dumb_terminal?).to be true
    end

    it "returns false for normal terminals" do
      ENV["TERM"] = "xterm-256color"
      expect(described_class.dumb_terminal?).to be false
    end
  end

  describe ".columns" do
    it "returns columns from winsize" do
      output = double("output", tty?: true, winsize: [24, 120])
      expect(described_class.columns(output)).to eq(120)
    end

    it "returns default for non-TTY" do
      output = StringIO.new
      expect(described_class.columns(output)).to eq(80)
    end

    it "allows custom default" do
      output = StringIO.new
      expect(described_class.columns(output, default: 100)).to eq(100)
    end

    it "handles zero columns from winsize" do
      output = double("output", tty?: true, winsize: [24, 0])
      expect(described_class.columns(output)).to eq(80)
    end
  end

  describe ".rows" do
    it "returns rows from winsize" do
      output = double("output", tty?: true, winsize: [40, 120])
      expect(described_class.rows(output)).to eq(40)
    end

    it "returns default for non-TTY" do
      output = StringIO.new
      expect(described_class.rows(output)).to eq(24)
    end
  end

  describe ".dimensions" do
    it "returns [rows, columns]" do
      output = double("output", tty?: true, winsize: [40, 120])
      expect(described_class.dimensions(output)).to eq([40, 120])
    end
  end

  describe ".colors_supported?" do
    before do
      @original_no_color = ENV["NO_COLOR"]
      @original_force_color = ENV["FORCE_COLOR"]
      @original_term = ENV["TERM"]
    end

    after do
      ENV["NO_COLOR"] = @original_no_color
      ENV["FORCE_COLOR"] = @original_force_color
      ENV["TERM"] = @original_term
    end

    it "returns false when NO_COLOR is set" do
      ENV["NO_COLOR"] = "1"
      expect(described_class.colors_supported?).to be false
    end

    it "returns true when FORCE_COLOR is set" do
      ENV.delete("NO_COLOR")
      ENV["FORCE_COLOR"] = "1"
      expect(described_class.colors_supported?).to be true
    end

    it "returns false for dumb terminal" do
      ENV.delete("NO_COLOR")
      ENV.delete("FORCE_COLOR")
      ENV["TERM"] = "dumb"
      output = double("output", tty?: true)
      expect(described_class.colors_supported?(output)).to be false
    end
  end
end
