RSpec.describe Clack::Core::Cursor do
  describe ".hide" do
    it "returns hide cursor sequence" do
      expect(described_class.hide).to eq("\e[?25l")
    end
  end

  describe ".show" do
    it "returns show cursor sequence" do
      expect(described_class.show).to eq("\e[?25h")
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

  describe ".move" do
    it "generates relative movement" do
      expect(described_class.move(5, 3)).to eq("\e[5C\e[3B")
      expect(described_class.move(-2, -4)).to eq("\e[2D\e[4A")
    end

    it "handles zero movement" do
      expect(described_class.move(0, 0)).to eq("")
    end
  end
end
