RSpec.describe Clack::Prompts::Spinner do
  let(:output) { StringIO.new }
  let(:spinner) { described_class.new(output: output) }

  describe "#start" do
    it "starts the spinner" do
      spinner.start("Loading")
      sleep 0.15
      spinner.stop("Done")
      expect(output.string).to include("Loading")
    end

    it "returns self for chaining" do
      result = spinner.start("Test")
      spinner.stop
      expect(result).to be(spinner)
    end
  end

  describe "#stop" do
    it "stops with success symbol" do
      spinner.start("Working")
      sleep 0.1
      spinner.stop("Complete!")
      expect(output.string).to include("Complete!")
      expect(output.string).to include(Clack::Symbols::S_STEP_SUBMIT)
    end
  end

  describe "#error" do
    it "stops with error symbol" do
      spinner.start("Working")
      sleep 0.1
      spinner.error("Failed!")
      expect(output.string).to include("Failed!")
      expect(output.string).to include(Clack::Symbols::S_STEP_ERROR)
    end
  end

  describe "#cancel" do
    it "stops with cancel symbol and sets cancelled flag" do
      spinner.start("Working")
      sleep 0.1
      spinner.cancel("Cancelled!")
      expect(output.string).to include("Cancelled!")
      expect(spinner.cancelled?).to be true
    end
  end

  describe "#message" do
    it "updates the message" do
      spinner.start("Initial")
      sleep 0.1
      spinner.message("Updated")
      sleep 0.15
      spinner.stop("Done")
      expect(output.string).to include("Updated")
    end
  end

  describe "#clear" do
    it "clears without output" do
      spinner.start("Test")
      sleep 0.1
      spinner.clear
      # Should not crash
    end
  end
end
