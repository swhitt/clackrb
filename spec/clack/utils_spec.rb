# frozen_string_literal: true

require "spec_helper"

RSpec.describe Clack::Utils do
  describe ".strip_ansi" do
    it "removes ANSI color codes" do
      colored = "\e[32mgreen\e[0m"
      expect(described_class.strip_ansi(colored)).to eq("green")
    end

    it "removes multiple ANSI codes" do
      text = "\e[1m\e[32mbold green\e[0m text"
      expect(described_class.strip_ansi(text)).to eq("bold green text")
    end

    it "handles text without ANSI codes" do
      expect(described_class.strip_ansi("plain text")).to eq("plain text")
    end

    it "handles nil gracefully" do
      expect(described_class.strip_ansi(nil)).to eq("")
    end
  end

  describe ".visible_length" do
    it "returns length excluding ANSI codes" do
      colored = "\e[32mgreen\e[0m"
      expect(described_class.visible_length(colored)).to eq(5)
    end

    it "returns actual length for plain text" do
      expect(described_class.visible_length("hello")).to eq(5)
    end
  end

  describe ".wrap" do
    it "wraps text at specified width" do
      text = "hello world foo bar"
      expect(described_class.wrap(text, 10)).to eq("hello\nworld foo\nbar")
    end

    it "handles single long word" do
      expect(described_class.wrap("superlongword", 5)).to eq("super\nlongw\nord")
    end

    it "preserves existing newlines" do
      text = "line1\nline2"
      expect(described_class.wrap(text, 80)).to eq("line1\nline2")
    end

    it "returns original for zero or negative width" do
      expect(described_class.wrap("test", 0)).to eq("test")
      expect(described_class.wrap("test", -1)).to eq("test")
    end
  end

  describe ".wrap_with_prefix" do
    it "adds prefix to each wrapped line" do
      text = "hello world"
      result = described_class.wrap_with_prefix(text, "| ", 10)
      expect(result).to eq("| hello\n| world")
    end
  end

  describe ".truncate" do
    it "truncates with ellipsis" do
      expect(described_class.truncate("hello world", 8)).to eq("hello...")
    end

    it "returns original if within width" do
      expect(described_class.truncate("hello", 10)).to eq("hello")
    end

    it "handles very small width" do
      expect(described_class.truncate("hello", 2)).to eq("...")
    end

    it "uses custom ellipsis" do
      expect(described_class.truncate("hello world", 8, ellipsis: "~")).to eq("hello w~")
    end
  end
end
