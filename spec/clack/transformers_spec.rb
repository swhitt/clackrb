# frozen_string_literal: true

RSpec.describe Clack::Transformers do
  describe ".resolve" do
    it "returns nil for nil" do
      expect(described_class.resolve(nil)).to be_nil
    end

    it "returns proc as-is" do
      proc = ->(v) { v.upcase }
      expect(described_class.resolve(proc)).to eq(proc)
    end

    it "looks up symbol in registry" do
      expect(described_class.resolve(:strip)).to eq(described_class::REGISTRY[:strip])
    end

    it "raises for unknown symbol" do
      expect { described_class.resolve(:unknown) }.to raise_error(ArgumentError, /Unknown transformer/)
    end

    it "raises for invalid type" do
      expect { described_class.resolve("string") }.to raise_error(ArgumentError, /must be a Symbol or respond to #call/)
    end
  end

  describe ".strip" do
    it "removes leading and trailing whitespace" do
      expect(described_class.strip.call("  hello  ")).to eq("hello")
    end

    it "handles nil by converting to empty string" do
      expect(described_class.strip.call(nil)).to eq("")
    end

    it "handles empty string" do
      expect(described_class.strip.call("")).to eq("")
    end
  end

  describe ".trim" do
    it "is an alias for strip" do
      expect(described_class.trim).to eq(described_class.strip)
    end
  end

  describe ".downcase" do
    it "converts to lowercase" do
      expect(described_class.downcase.call("HELLO")).to eq("hello")
    end

    it "handles nil" do
      expect(described_class.downcase.call(nil)).to eq("")
    end
  end

  describe ".upcase" do
    it "converts to uppercase" do
      expect(described_class.upcase.call("hello")).to eq("HELLO")
    end
  end

  describe ".capitalize" do
    it "capitalizes first letter" do
      expect(described_class.capitalize.call("hello world")).to eq("Hello world")
    end

    it "lowercases rest" do
      expect(described_class.capitalize.call("HELLO")).to eq("Hello")
    end
  end

  describe ".titlecase" do
    it "capitalizes first letter of each word" do
      expect(described_class.titlecase.call("hello world")).to eq("Hello World")
    end

    it "handles mixed case" do
      expect(described_class.titlecase.call("hELLO wORLD")).to eq("Hello World")
    end
  end

  describe ".squish" do
    it "strips and collapses whitespace" do
      expect(described_class.squish.call("  hello   world  ")).to eq("hello world")
    end

    it "handles tabs and newlines" do
      expect(described_class.squish.call("hello\t\nworld")).to eq("hello world")
    end
  end

  describe ".compact" do
    it "removes all whitespace" do
      expect(described_class.compact.call("  hello   world  ")).to eq("helloworld")
    end

    it "handles tabs and newlines" do
      expect(described_class.compact.call("hello\t\nworld")).to eq("helloworld")
    end
  end

  describe ".to_integer" do
    it "parses as integer" do
      expect(described_class.to_integer.call("42")).to eq(42)
    end

    it "handles negative numbers" do
      expect(described_class.to_integer.call("-42")).to eq(-42)
    end

    it "handles non-numeric strings" do
      expect(described_class.to_integer.call("abc")).to eq(0)
    end

    it "handles nil" do
      expect(described_class.to_integer.call(nil)).to eq(0)
    end

    it "truncates floats" do
      expect(described_class.to_integer.call("3.14")).to eq(3)
    end
  end

  describe ".to_float" do
    it "parses as float" do
      expect(described_class.to_float.call("3.14")).to eq(3.14)
    end

    it "handles negative numbers" do
      expect(described_class.to_float.call("-3.14")).to eq(-3.14)
    end

    it "handles nil" do
      expect(described_class.to_float.call(nil)).to eq(0.0)
    end
  end

  describe ".digits_only" do
    it "extracts only digits" do
      expect(described_class.digits_only.call("(555) 123-4567")).to eq("5551234567")
    end

    it "handles no digits" do
      expect(described_class.digits_only.call("abc")).to eq("")
    end
  end

  describe ".chain" do
    it "applies transformers in order" do
      transformer = described_class.chain(:strip, :downcase)
      expect(transformer.call("  HELLO  ")).to eq("hello")
    end

    it "works with symbol shortcuts" do
      transformer = described_class.chain(:strip, :upcase)
      expect(transformer.call("  hello  ")).to eq("HELLO")
    end

    it "works with procs" do
      transformer = described_class.chain(
        :strip,
        ->(v) { v.reverse }
      )
      expect(transformer.call("  hello  ")).to eq("olleh")
    end

    it "handles empty chain" do
      transformer = described_class.chain
      expect(transformer.call("hello")).to eq("hello")
    end

    it "handles single transformer" do
      transformer = described_class.chain(:strip)
      expect(transformer.call("  hello  ")).to eq("hello")
    end
  end
end
