# frozen_string_literal: true

require "clack/testing"

RSpec.describe Clack::Testing do
  describe ".simulate" do
    it "simulates text input" do
      result = described_class.simulate(Clack.method(:text), message: "Name?") do |p|
        p.type("Alice")
        p.submit
      end

      expect(result).to eq("Alice")
    end

    it "simulates select with navigation" do
      result = described_class.simulate(
        Clack.method(:select),
        message: "Pick",
        options: %w[a b c]
      ) do |p|
        p.down
        p.submit
      end

      expect(result).to eq("b")
    end

    it "simulates multiselect with toggle" do
      result = described_class.simulate(
        Clack.method(:multiselect),
        message: "Pick",
        options: %w[a b c]
      ) do |p|
        p.toggle # select "a"
        p.down
        p.toggle # select "b"
        p.submit
      end

      expect(result).to contain_exactly("a", "b")
    end

    it "simulates confirm" do
      result = described_class.simulate(
        Clack.method(:confirm),
        message: "Continue?"
      ) do |p|
        p.submit
      end

      expect(result).to be true
    end

    it "simulates cancellation" do
      result = described_class.simulate(Clack.method(:text), message: "Name?") do |p|
        p.cancel
      end

      expect(Clack.cancel?(result)).to be true
    end

    it "simulates backspace" do
      result = described_class.simulate(Clack.method(:text), message: "Name?") do |p|
        p.type("Alicee")
        p.backspace
        p.submit
      end

      expect(result).to eq("Alice")
    end

    it "simulates arbitrary keys" do
      result = described_class.simulate(
        Clack.method(:confirm),
        message: "Yes?"
      ) do |p|
        p.key("n")
        p.submit
      end

      expect(result).to be false
    end
  end

  describe ".simulate_with_output" do
    it "returns both result and output" do
      result, output = described_class.simulate_with_output(
        Clack.method(:text),
        message: "Name?"
      ) do |p|
        p.type("Alice")
        p.submit
      end

      expect(result).to eq("Alice")
      expect(output).to include("Name?")
    end
  end

  describe Clack::Testing::PromptDriver do
    subject { described_class.new }

    it "accumulates keys from type" do
      subject.type("hi")
      expect(subject.keys).to eq(%w[h i])
    end

    it "adds submit key" do
      subject.submit
      expect(subject.keys).to eq(["\r"])
    end

    it "adds cancel key" do
      subject.cancel
      expect(subject.keys).to eq(["\e"])
    end

    it "adds navigation keys" do
      subject.up
      subject.down
      subject.left
      subject.right
      expect(subject.keys).to eq(["\e[A", "\e[B", "\e[D", "\e[C"])
    end

    it "adds toggle key" do
      subject.toggle
      expect(subject.keys).to eq([" "])
    end

    it "adds tab key" do
      subject.tab
      expect(subject.keys).to eq(["\t"])
    end

    it "adds ctrl_d key" do
      subject.ctrl_d
      expect(subject.keys).to eq(["\u0004"])
    end

    it "looks up named keys" do
      subject.key(:escape)
      expect(subject.keys).to eq(["\e"])
    end

    it "passes raw characters" do
      subject.key("x")
      expect(subject.keys).to eq(["x"])
    end
  end
end
