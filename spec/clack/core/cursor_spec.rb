# frozen_string_literal: true

RSpec.describe Clack::Core::Cursor do
  before { described_class.enabled = true }
  after { described_class.enabled = nil }

  describe ".enabled?" do
    it "delegates to Environment.colors_supported? when not overridden" do
      described_class.enabled = nil
      allow(Clack::Environment).to receive(:colors_supported?).and_return(false)
      expect(described_class.enabled?).to be false

      allow(Clack::Environment).to receive(:colors_supported?).and_return(true)
      expect(described_class.enabled?).to be true
    end

    it "respects explicit override" do
      described_class.enabled = false
      expect(described_class.enabled?).to be false

      described_class.enabled = true
      expect(described_class.enabled?).to be true
    end
  end

  describe ".hide" do
    it "returns hide cursor sequence" do
      expect(described_class.hide).to eq("\e[?25l")
    end

    it "returns empty string when disabled" do
      described_class.enabled = false
      expect(described_class.hide).to eq("")
    end
  end

  describe ".show" do
    it "returns show cursor sequence" do
      expect(described_class.show).to eq("\e[?25h")
    end

    it "returns empty string when disabled" do
      described_class.enabled = false
      expect(described_class.show).to eq("")
    end
  end

  describe ".up" do
    it "moves cursor up" do
      expect(described_class.up(3)).to eq("\e[3A")
    end
  end

  describe ".down" do
    it "moves cursor down" do
      expect(described_class.down(2)).to eq("\e[2B")
    end
  end

  describe ".clear_line" do
    it "clears entire line" do
      expect(described_class.clear_line).to eq("\e[2K")
    end
  end

  describe ".clear_down" do
    it "clears from cursor down" do
      expect(described_class.clear_down).to eq("\e[J")
    end
  end
end
