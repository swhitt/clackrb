# frozen_string_literal: true

RSpec.describe Clack::Validators do
  describe ".required" do
    let(:validator) { described_class.required }

    it "returns nil for non-empty string" do
      expect(validator.call("hello")).to be_nil
    end

    it "returns error for empty string" do
      expect(validator.call("")).to eq("This field is required")
    end

    it "returns error for whitespace only" do
      expect(validator.call("   ")).to eq("This field is required")
    end

    it "returns error for nil" do
      expect(validator.call(nil)).to eq("This field is required")
    end

    it "accepts custom message" do
      validator = described_class.required("Name is required")
      expect(validator.call("")).to eq("Name is required")
    end
  end

  describe ".min_length" do
    let(:validator) { described_class.min_length(3) }

    it "returns nil for string meeting minimum" do
      expect(validator.call("abc")).to be_nil
    end

    it "returns nil for string exceeding minimum" do
      expect(validator.call("abcd")).to be_nil
    end

    it "returns error for short string" do
      expect(validator.call("ab")).to eq("Must be at least 3 characters")
    end

    it "accepts custom message" do
      validator = described_class.min_length(3, "Too short!")
      expect(validator.call("ab")).to eq("Too short!")
    end
  end

  describe ".max_length" do
    let(:validator) { described_class.max_length(5) }

    it "returns nil for string within limit" do
      expect(validator.call("hello")).to be_nil
    end

    it "returns nil for shorter string" do
      expect(validator.call("hi")).to be_nil
    end

    it "returns error for long string" do
      expect(validator.call("toolong")).to eq("Must be at most 5 characters")
    end

    it "accepts custom message" do
      validator = described_class.max_length(5, "Too long!")
      expect(validator.call("toolong")).to eq("Too long!")
    end
  end

  describe ".format" do
    let(:validator) { described_class.format(/^\d+$/, "Must be numeric") }

    it "returns nil for matching string" do
      expect(validator.call("123")).to be_nil
    end

    it "returns error for non-matching string" do
      expect(validator.call("abc")).to eq("Must be numeric")
    end
  end

  describe ".one_of" do
    let(:validator) { described_class.one_of(%w[red green blue]) }

    it "returns nil for valid value" do
      expect(validator.call("red")).to be_nil
    end

    it "returns error for invalid value" do
      expect(validator.call("yellow")).to eq("Must be one of: red, green, blue")
    end

    it "accepts custom message" do
      validator = described_class.one_of(%w[a b], "Invalid choice")
      expect(validator.call("c")).to eq("Invalid choice")
    end
  end

  describe ".integer" do
    let(:validator) { described_class.integer }

    it "returns nil for integer string" do
      expect(validator.call("42")).to be_nil
    end

    it "returns nil for negative integer" do
      expect(validator.call("-5")).to be_nil
    end

    it "returns error for non-integer" do
      expect(validator.call("abc")).to eq("Must be a number")
    end

    it "returns error for float" do
      expect(validator.call("3.14")).to eq("Must be a number")
    end
  end

  describe ".in_range" do
    let(:validator) { described_class.in_range(1..10) }

    it "returns nil for value in range" do
      expect(validator.call("5")).to be_nil
    end

    it "returns nil for boundary values" do
      expect(validator.call("1")).to be_nil
      expect(validator.call("10")).to be_nil
    end

    it "returns error for value out of range" do
      expect(validator.call("0")).to eq("Must be between 1 and 10")
    end

    it "returns error for non-integer" do
      expect(validator.call("abc")).to eq("Must be between 1 and 10")
    end
  end

  describe ".combine" do
    let(:validator) do
      described_class.combine(
        described_class.required,
        described_class.min_length(3)
      )
    end

    it "returns nil when all validators pass" do
      expect(validator.call("hello")).to be_nil
    end

    it "returns first error when first validator fails" do
      expect(validator.call("")).to eq("This field is required")
    end

    it "returns second error when first passes but second fails" do
      expect(validator.call("hi")).to eq("Must be at least 3 characters")
    end
  end

  describe ".email" do
    let(:validator) { described_class.email }

    it "returns nil for valid email" do
      expect(validator.call("user@example.com")).to be_nil
    end

    it "returns error for invalid email" do
      expect(validator.call("not-an-email")).to eq("Must be a valid email address")
    end

    it "returns error for email without domain" do
      expect(validator.call("user@")).to eq("Must be a valid email address")
    end
  end

  describe ".url" do
    let(:validator) { described_class.url }

    it "returns nil for valid http url" do
      expect(validator.call("http://example.com")).to be_nil
    end

    it "returns nil for valid https url" do
      expect(validator.call("https://example.com/path")).to be_nil
    end

    it "returns error for invalid url" do
      expect(validator.call("not-a-url")).to eq("Must be a valid URL")
    end

    it "returns error for ftp url" do
      expect(validator.call("ftp://example.com")).to eq("Must be a valid URL")
    end
  end

  describe ".path_exists" do
    let(:validator) { described_class.path_exists }

    it "returns nil for existing path" do
      expect(validator.call(__FILE__)).to be_nil
    end

    it "returns error for non-existent path" do
      expect(validator.call("/nonexistent/path")).to eq("Path does not exist")
    end
  end

  describe ".directory_exists" do
    let(:validator) { described_class.directory_exists }

    it "returns nil for existing directory" do
      expect(validator.call(File.dirname(__FILE__))).to be_nil
    end

    it "returns error for file (not directory)" do
      expect(validator.call(__FILE__)).to eq("Directory does not exist")
    end

    it "returns error for non-existent path" do
      expect(validator.call("/nonexistent/dir")).to eq("Directory does not exist")
    end
  end
end
