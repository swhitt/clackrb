# frozen_string_literal: true

RSpec.describe Clack::Core::Settings do
  after do
    described_class.reset!
  end

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

    it "respects custom aliases" do
      described_class.update(aliases: {"y" => :enter, "n" => :cancel})
      expect(described_class.action?("y")).to eq(:enter)
      expect(described_class.action?("n")).to eq(:cancel)
    end
  end

  describe ".config" do
    it "returns current configuration" do
      config = described_class.config
      expect(config).to be_a(Hash)
      expect(config).to have_key(:aliases)
      expect(config).to have_key(:with_guide)
    end

    it "returns a copy, not the original" do
      config1 = described_class.config
      config2 = described_class.config
      expect(config1).not_to be(config2)
    end
  end

  describe ".update" do
    it "merges custom aliases with defaults" do
      described_class.update(aliases: {"y" => :enter})
      config = described_class.config
      expect(config[:aliases]["y"]).to eq(:enter)
      expect(config[:aliases]["\e[A"]).to eq(:up) # Default still works
    end

    it "updates with_guide setting" do
      described_class.update(with_guide: false)
      expect(described_class.with_guide?).to be false
    end

    it "returns updated config" do
      result = described_class.update(with_guide: false)
      expect(result[:with_guide]).to be false
    end
  end

  describe ".reset!" do
    it "restores default settings" do
      described_class.update(aliases: {"x" => :enter}, with_guide: false)
      described_class.reset!

      expect(described_class.action?("x")).to be_nil
      expect(described_class.with_guide?).to be true
    end
  end

  describe ".with_guide?" do
    it "returns true by default" do
      expect(described_class.with_guide?).to be true
    end

    it "returns false when disabled" do
      described_class.update(with_guide: false)
      expect(described_class.with_guide?).to be false
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
