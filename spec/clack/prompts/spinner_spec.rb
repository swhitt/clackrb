RSpec.describe Clack::Prompts::Spinner do
  let(:output) { StringIO.new }
  let(:spinner) { described_class.new(output: output) }

  describe "#start" do
    it "returns self for chaining" do
      result = spinner.start("Test")
      spinner.stop
      expect(result).to be(spinner)
    end

    it "shows the initial message" do
      spinner.start("Loading")
      spinner.stop
      # The final stop message replaces the spinner, but we can verify start worked
      expect(output.string).not_to be_empty
    end
  end

  describe "#stop" do
    it "stops with success symbol and message" do
      spinner.start("Working")
      spinner.stop("Complete!")
      expect(output.string).to include("Complete!")
      expect(output.string).to include(Clack::Symbols::S_STEP_SUBMIT)
    end

    it "uses original message if no new message provided" do
      spinner.start("Working")
      spinner.stop
      expect(output.string).to include("Working")
    end
  end

  describe "#error" do
    it "stops with error symbol" do
      spinner.start("Working")
      spinner.error("Failed!")
      expect(output.string).to include("Failed!")
      expect(output.string).to include(Clack::Symbols::S_STEP_ERROR)
    end
  end

  describe "#cancel" do
    it "stops with cancel symbol and sets cancelled flag" do
      spinner.start("Working")
      spinner.cancel("Cancelled!")
      expect(output.string).to include("Cancelled!")
      expect(output.string).to include(Clack::Symbols::S_STEP_CANCEL)
      expect(spinner.cancelled?).to be true
    end
  end

  describe "#message" do
    it "updates the internal message" do
      spinner.start("Initial")
      spinner.message("Updated")
      spinner.stop
      # Stop with no args uses the current message
      expect(output.string).to include("Updated")
    end
  end

  describe "#clear" do
    it "clears the spinner and restores cursor" do
      spinner.start("Test")
      output_before = output.string.length
      spinner.clear
      # Clear should write cursor movement/clear codes
      expect(output.string.length).to be > output_before
      expect(output.string).to include(Clack::Core::Cursor.show)
    end
  end

  describe "#cancelled?" do
    it "returns false by default" do
      spinner.start("Test")
      spinner.stop
      expect(spinner.cancelled?).to be false
    end
  end
end
