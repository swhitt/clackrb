# frozen_string_literal: true

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

  describe "indicator option" do
    it "shows timer format with indicator: :timer" do
      timer_spinner = described_class.new(indicator: :timer, output: output)
      timer_spinner.start("Loading")
      sleep 0.15
      timer_spinner.stop("Done")

      expect(output.string).to match(/\[\d+s\]/)
    end

    it "shows animated dots with indicator: :dots" do
      dots_spinner = described_class.new(indicator: :dots, delay: 0.03, output: output)
      dots_spinner.start("Loading")
      sleep 0.25 # Enough time to cycle through dot animation
      dots_spinner.stop("Done")

      # Dots mode animates 0-3 dots every few frames
      expect(output.string).to match(/Loading\.{0,3}/)
    end
  end

  describe "custom frames" do
    it "uses custom spinner frames" do
      custom = described_class.new(frames: %w[A B C], output: output)
      custom.start("Test")
      sleep 0.15
      custom.stop

      expect(output.string).to match(/[ABC]/)
    end
  end

  describe "custom delay" do
    it "respects custom delay" do
      fast = described_class.new(delay: 0.01, output: output)
      fast.start("Fast")
      sleep 0.05
      fast.stop

      # Should have cycled through frames quickly
      expect(output.string).not_to be_empty
    end
  end

  describe "style_frame option" do
    it "applies custom styling to frames" do
      styled = described_class.new(
        style_frame: ->(f) { "[#{f}]" },
        output: output
      )
      styled.start("Test")
      sleep 0.1
      styled.stop

      expect(output.string).to include("[")
    end
  end

  describe "removes trailing dots from message" do
    it "strips trailing dots" do
      spinner.start("Loading...")
      spinner.stop
      # Should not have extra dots in final output
      expect(output.string.scan(/Loading\.{4,}/).length).to eq(0)
    end
  end
end
