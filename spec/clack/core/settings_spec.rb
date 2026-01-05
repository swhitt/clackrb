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

  describe ".cancel?" do
    it "recognizes escape" do
      expect(described_class.cancel?("\e")).to be true
    end

    it "recognizes Ctrl+C" do
      expect(described_class.cancel?("\u0003")).to be true
    end

    it "returns false for other keys" do
      expect(described_class.cancel?("q")).to be false
    end
  end

  describe ".enter?" do
    it "recognizes enter key" do
      expect(described_class.enter?("\r")).to be true
    end

    it "returns false for other keys" do
      expect(described_class.enter?(" ")).to be false
    end
  end
end
