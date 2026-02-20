# frozen_string_literal: true

require "clack/testing"

RSpec.describe Clack::Prompts::Range do
  describe "basic interaction" do
    it "submits default (min) value" do
      result = Clack::Testing.simulate(Clack.method(:range), message: "Volume", min: 0, max: 100) do |p|
        p.submit
      end

      expect(result).to eq(0)
    end

    it "submits custom default value" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 100, default: 50
      ) do |p|
        p.submit
      end

      expect(result).to eq(50)
    end

    it "increments with right arrow" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 10, step: 1, default: 5
      ) do |p|
        p.right
        p.right
        p.submit
      end

      expect(result).to eq(7)
    end

    it "decrements with left arrow" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 10, step: 1, default: 5
      ) do |p|
        p.left
        p.left
        p.submit
      end

      expect(result).to eq(3)
    end

    it "increments with up arrow" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 10, step: 1, default: 5
      ) do |p|
        p.up
        p.submit
      end

      expect(result).to eq(6)
    end

    it "decrements with down arrow" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 10, step: 1, default: 5
      ) do |p|
        p.down
        p.submit
      end

      expect(result).to eq(4)
    end

    it "clamps at max" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 3, step: 1, default: 3
      ) do |p|
        p.right
        p.right
        p.submit
      end

      expect(result).to eq(3)
    end

    it "clamps at min" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 10, step: 1, default: 0
      ) do |p|
        p.left
        p.left
        p.submit
      end

      expect(result).to eq(0)
    end

    it "supports step increments" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 100, step: 10, default: 50
      ) do |p|
        p.right
        p.right
        p.submit
      end

      expect(result).to eq(70)
    end

    it "cancels with escape" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 100
      ) do |p|
        p.cancel
      end

      expect(Clack.cancel?(result)).to be true
    end
  end

  describe "rendering" do
    it "shows slider in output" do
      _, output = Clack::Testing.simulate_with_output(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 100, default: 50
      ) do |p|
        p.submit
      end

      expect(output).to include("Volume")
    end
  end

  describe "validation" do
    it "raises for min >= max" do
      expect {
        Clack::Prompts::Range.new(message: "Bad", min: 10, max: 5)
      }.to raise_error(ArgumentError, /min must be less than max/)
    end

    it "raises for non-positive step" do
      expect {
        Clack::Prompts::Range.new(message: "Bad", min: 0, max: 10, step: 0)
      }.to raise_error(ArgumentError, /step must be positive/)
    end

    it "supports custom validation" do
      result = Clack::Testing.simulate(
        Clack.method(:range),
        message: "Volume",
        min: 0, max: 100, default: 50,
        validate: ->(v) { "Must be even" if v.odd? }
      ) do |p|
        p.right # 51, odd
        p.submit # validation fails
        p.right # 52, even
        p.submit
      end

      expect(result).to eq(52)
    end
  end

  describe "CI mode" do
    around do |example|
      Clack.update_settings(ci_mode: true)
      example.run
    ensure
      Clack::Core::Settings.reset!
    end

    it "auto-submits with default" do
      output = StringIO.new
      result = Clack.range(message: "Volume", min: 0, max: 100, default: 50, output: output)
      expect(result).to eq(50)
    end

    it "auto-submits with min when no default" do
      output = StringIO.new
      result = Clack.range(message: "Volume", min: 0, max: 100, output: output)
      expect(result).to eq(0)
    end
  end
end
