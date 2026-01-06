# frozen_string_literal: true

RSpec.describe Clack::TaskLog do
  let(:output) { StringIO.new }

  describe "#initialize" do
    it "renders title on creation" do
      described_class.new(title: "Building...", output: output)
      expect(output.string).to include("Building...")
      expect(output.string).to include(Clack::Symbols::S_STEP_SUBMIT)
    end
  end

  describe "#message" do
    it "adds messages to buffer" do
      tl = described_class.new(title: "Test", output: output)
      tl.message("Step 1")
      tl.message("Step 2")
      tl.success("Done")

      expect(output.string).to include("Done")
    end

    it "strips cursor movement codes" do
      tl = described_class.new(title: "Test", output: output)
      tl.message("Text\e[2AMore")
      tl.success("Done")
      # Should not crash and should complete
      expect(output.string).to include("Done")
    end
  end

  describe "#success" do
    it "shows success message" do
      tl = described_class.new(title: "Test", output: output)
      tl.success("Completed!")

      expect(output.string).to include("Completed!")
      expect(output.string).to include(Clack::Symbols::S_STEP_SUBMIT)
    end

    it "shows log when show_log: true" do
      tl = described_class.new(title: "Test", output: output)
      tl.message("Log line")
      tl.success("Done", show_log: true)

      expect(output.string).to include("Log line")
    end
  end

  describe "#error" do
    it "shows error message" do
      tl = described_class.new(title: "Test", output: output)
      tl.error("Failed!")

      expect(output.string).to include("Failed!")
      expect(output.string).to include(Clack::Symbols::S_STEP_ERROR)
    end

    it "shows log by default" do
      tl = described_class.new(title: "Test", output: output)
      tl.message("Error details")
      tl.error("Failed")

      expect(output.string).to include("Error details")
    end

    it "hides log when show_log: false" do
      tl = described_class.new(title: "Test", output: output)
      tl.message("Secret")
      output_before_error = output.string.dup
      tl.error("Failed", show_log: false)

      # The log message should not appear after error
      final_output = output.string[output_before_error.length..]
      expect(final_output).not_to include("Secret")
    end
  end

  describe "#group" do
    it "creates a group" do
      tl = described_class.new(title: "Test", output: output)
      grp = tl.group("My Group")

      expect(grp).to be_a(Clack::TaskLogGroup)
    end
  end

  describe "limit option" do
    it "respects line limit" do
      tl = described_class.new(title: "Test", limit: 2, output: output)
      tl.message("Line 1")
      tl.message("Line 2")
      tl.message("Line 3")
      # Only last 2 lines should be in buffer
      expect(tl.instance_variable_get(:@buffer).size).to eq(2)
    end
  end

  describe "retain_log option" do
    it "keeps full buffer for error display" do
      tl = described_class.new(title: "Test", limit: 2, retain_log: true, output: output)
      tl.message("Line 1")
      tl.message("Line 2")
      tl.message("Line 3")
      tl.error("Failed")

      expect(output.string).to include("Line 1")
      expect(output.string).to include("Line 3")
    end
  end
end

RSpec.describe Clack::TaskLogGroup do
  let(:output) { StringIO.new }
  let(:task_log) { Clack::TaskLog.new(title: "Test", output: output) }

  describe "#message" do
    it "adds message to parent" do
      grp = task_log.group("Group")
      grp.message("Group message")
      task_log.success("Done", show_log: true)

      expect(output.string).to include("Group message")
    end
  end

  describe "#success" do
    it "adds success indicator" do
      grp = task_log.group("Group")
      grp.success("Task done")
      task_log.success("All done", show_log: true)

      expect(output.string).to include("Task done")
    end
  end

  describe "#error" do
    it "adds error indicator" do
      grp = task_log.group("Group")
      grp.error("Task failed")
      task_log.error("Failed")

      expect(output.string).to include("Task failed")
    end
  end
end
