RSpec.describe Clack do
  it "has a version number" do
    expect(Clack::VERSION).not_to be_nil
  end

  describe ".cancel?" do
    it "returns true for CANCEL" do
      expect(Clack.cancel?(Clack::CANCEL)).to be true
    end

    it "returns false for other values" do
      expect(Clack.cancel?("hello")).to be false
      expect(Clack.cancel?(nil)).to be false
      expect(Clack.cancel?(false)).to be false
    end
  end

  describe ".intro" do
    it "outputs intro with title" do
      output = StringIO.new
      Clack.intro("test-app", output: output)
      expect(output.string).to include("test-app")
      expect(output.string).to include(Clack::Symbols::S_BAR_START)
    end
  end

  describe ".outro" do
    it "outputs outro with message" do
      output = StringIO.new
      Clack.outro("Done!", output: output)
      expect(output.string).to include("Done!")
      expect(output.string).to include(Clack::Symbols::S_BAR_END)
    end
  end

  describe ".cancel" do
    it "outputs cancel message in red" do
      output = StringIO.new
      Clack.cancel("Operation cancelled", output: output)
      expect(output.string).to include("Operation cancelled")
    end
  end
end
