# frozen_string_literal: true

RSpec.describe Clack::Transformers do
  describe ".strip" do
    it "removes leading and trailing whitespace" do
      expect(described_class.strip.call("  hello  ")).to eq("hello")
    end

    it "handles nil by converting to empty string" do
      expect(described_class.strip.call(nil)).to eq("")
    end
  end

  describe ".downcase" do
    it "converts to lowercase" do
      expect(described_class.downcase.call("HELLO")).to eq("hello")
    end
  end

  describe ".upcase" do
    it "converts to uppercase" do
      expect(described_class.upcase.call("hello")).to eq("HELLO")
    end
  end

  describe ".squish" do
    it "strips and collapses whitespace" do
      expect(described_class.squish.call("  hello   world  ")).to eq("hello world")
    end
  end

  describe ".to_integer" do
    it "parses as integer" do
      expect(described_class.to_integer.call("42")).to eq(42)
    end

    it "handles non-numeric strings" do
      expect(described_class.to_integer.call("abc")).to eq(0)
    end
  end

  describe ".to_float" do
    it "parses as float" do
      expect(described_class.to_float.call("3.14")).to eq(3.14)
    end
  end

  describe ".phone_us" do
    it "formats 10 digits as (XXX) XXX-XXXX" do
      expect(described_class.phone_us.call("5551234567")).to eq("(555) 123-4567")
    end

    it "extracts digits from formatted input" do
      expect(described_class.phone_us.call("555-123-4567")).to eq("(555) 123-4567")
    end

    it "handles input with extra characters" do
      expect(described_class.phone_us.call("(555) 123-4567")).to eq("(555) 123-4567")
    end

    it "takes last 10 digits if more provided" do
      expect(described_class.phone_us.call("15551234567")).to eq("(555) 123-4567")
    end

    it "returns original if not 10 digits" do
      expect(described_class.phone_us.call("123")).to eq("123")
    end
  end

  describe ".credit_card" do
    it "formats as groups of 4" do
      expect(described_class.credit_card.call("4111111111111111")).to eq("4111 1111 1111 1111")
    end

    it "handles input with spaces" do
      expect(described_class.credit_card.call("4111 1111 1111 1111")).to eq("4111 1111 1111 1111")
    end
  end

  describe ".ssn" do
    it "formats as XXX-XX-XXXX" do
      expect(described_class.ssn.call("123456789")).to eq("123-45-6789")
    end

    it "returns original if not 9 digits" do
      expect(described_class.ssn.call("12345")).to eq("12345")
    end
  end

  describe ".chain" do
    it "applies transformers in order" do
      transformer = described_class.chain(
        described_class.strip,
        described_class.downcase
      )
      expect(transformer.call("  HELLO  ")).to eq("hello")
    end

    it "works with custom lambdas" do
      transformer = described_class.chain(
        described_class.strip,
        ->(v) { v.reverse }
      )
      expect(transformer.call("  hello  ")).to eq("olleh")
    end
  end
end
