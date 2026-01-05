RSpec.describe Clack::Log do
  let(:output) { StringIO.new }

  describe ".message" do
    it "outputs message with bar" do
      described_class.message("Hello", output: output)
      expect(output.string).to include("Hello")
    end

    it "handles empty message" do
      described_class.message("", output: output)
      expect(output.string).to include(Clack::Symbols::S_BAR)
    end

    it "handles multiline messages" do
      described_class.message("Line 1\nLine 2", output: output)
      expect(output.string).to include("Line 1")
      expect(output.string).to include("Line 2")
    end
  end

  describe ".info" do
    it "outputs with info symbol" do
      described_class.info("Info message", output: output)
      expect(output.string).to include("Info message")
      expect(output.string).to include(Clack::Symbols::S_INFO)
    end
  end

  describe ".success" do
    it "outputs with success symbol" do
      described_class.success("Success!", output: output)
      expect(output.string).to include("Success!")
    end
  end

  describe ".warn" do
    it "outputs with warning symbol" do
      described_class.warn("Warning!", output: output)
      expect(output.string).to include("Warning!")
    end
  end

  describe ".error" do
    it "outputs with error symbol" do
      described_class.error("Error!", output: output)
      expect(output.string).to include("Error!")
    end
  end

  describe ".step" do
    it "outputs with step symbol" do
      described_class.step("Step complete", output: output)
      expect(output.string).to include("Step complete")
    end
  end
end
