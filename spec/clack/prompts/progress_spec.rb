RSpec.describe Clack::Prompts::Progress do
  let(:output) { StringIO.new }

  def create_progress(**opts)
    described_class.new(total: 10, output: output, **opts)
  end

  describe "edge cases" do
    it "handles total of zero without error" do
      progress = described_class.new(total: 0, output: output)
      progress.start("Processing...")

      expect(output.string).to include("100%")
    end
  end

  describe "#start" do
    it "begins rendering progress bar" do
      progress = create_progress(message: "Loading...")
      progress.start

      expect(output.string).to include("Loading...")
      expect(output.string).to include("[")
    end
  end

  describe "#advance" do
    it "increments current value and updates display" do
      progress = create_progress
      progress.start
      progress.advance(3)

      expect(output.string).to include("30%")
    end

    it "does not exceed total" do
      progress = create_progress
      progress.start
      progress.advance(15)

      expect(output.string).to include("100%")
    end
  end

  describe "#update" do
    it "sets current to specific value" do
      progress = create_progress
      progress.start
      progress.update(7)

      expect(output.string).to include("70%")
    end
  end

  describe "#message" do
    it "updates the message" do
      progress = create_progress
      progress.start("First")
      progress.message("Second")

      expect(output.string).to include("Second")
    end
  end

  describe "#stop" do
    it "completes progress and shows final message" do
      progress = create_progress
      progress.start
      progress.stop("Done!")

      expect(output.string).to include("Done!")
      expect(output.string).to include(Clack::Symbols::S_STEP_SUBMIT)
    end
  end

  describe "#error" do
    it "renders error state" do
      progress = create_progress
      progress.start
      progress.error("Failed!")

      expect(output.string).to include("Failed!")
    end
  end

  describe "progress calculation" do
    it "displays percentage correctly at 50%" do
      progress = create_progress
      progress.start
      progress.update(5)

      expect(output.string).to include("50%")
    end
  end
end
