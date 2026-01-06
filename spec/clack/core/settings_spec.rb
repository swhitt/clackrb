# frozen_string_literal: true

RSpec.describe Clack::Core::Settings do
  describe ".action?" do
    it "recognizes arrow keys" do
      expect(described_class.action?("\e[A")).to eq(:up)
      expect(described_class.action?("\e[B")).to eq(:down)
      expect(described_class.action?("\e[C")).to eq(:right)
      expect(described_class.action?("\e[D")).to eq(:left)
    end

    it "recognizes vim keys" do
      expect(described_class.action?("k")).to eq(:up)
      expect(described_class.action?("j")).to eq(:down)
      expect(described_class.action?("h")).to eq(:left)
      expect(described_class.action?("l")).to eq(:right)
    end

    it "recognizes enter" do
      expect(described_class.action?("\r")).to eq(:enter)
      expect(described_class.action?("\n")).to eq(:enter)
    end

    it "recognizes space" do
      expect(described_class.action?(" ")).to eq(:space)
    end

    it "returns nil for unknown keys" do
      expect(described_class.action?("x")).to be_nil
      expect(described_class.action?("a")).to be_nil
    end
  end

  describe ".printable?" do
    it "recognizes printable characters" do
      expect(described_class.printable?("a")).to be true
      expect(described_class.printable?(" ")).to be true
      expect(described_class.printable?("~")).to be true
    end

    it "rejects control characters" do
      expect(described_class.printable?("\t")).to be false
      expect(described_class.printable?("\n")).to be false
      expect(described_class.printable?("\e")).to be false
    end

    it "rejects nil and multi-char strings" do
      expect(described_class.printable?(nil)).to be_falsey
      expect(described_class.printable?("ab")).to be_falsey
    end
  end

  describe ".backspace?" do
    it "recognizes backspace" do
      expect(described_class.backspace?("\b")).to be true
    end

    it "recognizes delete" do
      expect(described_class.backspace?("\u007F")).to be true
    end

    it "returns false for other keys" do
      expect(described_class.backspace?("x")).to be false
    end
  end
end
