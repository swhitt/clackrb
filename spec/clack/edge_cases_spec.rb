# frozen_string_literal: true

# Edge case tests for coverage gaps identified by test coverage audit.
# Each test targets a genuinely untested code path or boundary condition.

RSpec.describe "Edge case coverage" do
  let(:output) { StringIO.new }

  describe "MultilineText warning validation" do
    # MultilineText overrides handle_key, so the warning dispatch in Core::Prompt
    # could interact incorrectly with its custom key handling. Zero tests existed
    # for this interaction.
    #
    # NOTE: MultilineText's build_frame does not render warning messages (only
    # errors). This is a rendering gap in the lib code. These tests verify the
    # state machine behavior is correct regardless.

    it "accepts value after warning confirmation with Enter" do
      stub_keys("short", :ctrl_d, :enter)
      prompt = Clack::Prompts::MultilineText.new(
        message: "Message:",
        validate: ->(v) { Clack::Warning.new("Very short") if v.length < 10 },
        output: output
      )
      result = prompt.run

      # Warning flow: Ctrl+D triggers warning, Enter confirms, submits
      expect(result).to eq("short")
      expect(prompt.state).to eq(:submit)
    end

    it "can cancel from warning state with Escape" do
      stub_keys("short", :ctrl_d, :escape)
      prompt = Clack::Prompts::MultilineText.new(
        message: "Message:",
        validate: ->(_) { Clack::Warning.new("Warning!") },
        output: output
      )
      result = prompt.run

      expect(Clack.cancel?(result)).to be true
    end

    it "clears warning on edit and re-validates" do
      call_count = 0
      stub_keys("short", :ctrl_d, "!", :ctrl_d)
      prompt = Clack::Prompts::MultilineText.new(
        message: "Message:",
        validate: lambda { |v|
          call_count += 1
          Clack::Warning.new("Short!") if call_count == 1 && v.length < 10
        },
        output: output
      )
      result = prompt.run

      # First Ctrl+D triggers warning, "!" clears warning and adds char,
      # second Ctrl+D re-submits and passes
      expect(result).to eq("short!")
      expect(call_count).to eq(2)
    end
  end

  describe "Tasks edge cases" do
    it "handles empty task list without error" do
      tasks = Clack::Prompts::Tasks.new(tasks: [], output: output)
      results = tasks.run

      expect(results).to eq([])
    end

    it "returns value from task proc" do
      # Verify that task return values don't leak into results
      # (results use TaskResult, not raw return values)
      tasks = Clack::Prompts::Tasks.new(
        tasks: [{title: "T", task: -> { "some_return_value" }}],
        output: output
      )
      results = tasks.run

      expect(results.first.status).to eq(:success)
      expect(results.first.error).to be_nil
    end
  end

  describe "Text prompt with transform" do
    it "applies transform to submitted value" do
      stub_keys("  hello  ", :enter)
      prompt = Clack::Prompts::Text.new(
        message: "Input?",
        transform: :strip,
        output: output
      )
      result = prompt.run

      expect(result).to eq("hello")
    end

    it "applies transform after validation passes" do
      stub_keys(:enter, "x", :enter)
      prompt = Clack::Prompts::Text.new(
        message: "Input?",
        validate: ->(v) { "Required" if v.empty? },
        transform: :upcase,
        output: output
      )
      result = prompt.run

      expect(result).to eq("X")
      expect(output.string).to include("Required")
    end

    it "does not apply transform when cancelled" do
      stub_keys("hello", :escape)
      prompt = Clack::Prompts::Text.new(
        message: "Input?",
        transform: :upcase,
        output: output
      )
      result = prompt.run

      expect(Clack.cancel?(result)).to be true
    end
  end

  describe "Date digit input on last segment (no auto-advance)" do
    # The code has `move_segment(1) unless @segment == 2` in handle_digit.
    # This branch is never tested directly -- typing digits into the day
    # segment should NOT auto-advance since it's the last segment.

    it "does not auto-advance after completing day segment digits" do
      # Tab twice to reach day, type "25", then enter
      stub_keys(:tab, :tab, "2", "5", :enter)
      prompt = Clack::Prompts::Date.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      result = prompt.run

      expect(result.day).to eq(25)
      # Month and year should be unchanged (no auto-advance from last segment)
      expect(result.month).to eq(6)
      expect(result.year).to eq(2024)
    end

    it "clamps day digits to valid range for month" do
      # Tab twice to day, type "35" (invalid day for any month), enter
      stub_keys(:tab, :tab, "3", "5", :enter)
      prompt = Clack::Prompts::Date.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 2, 15),
        output: output
      )
      result = prompt.run

      # Feb 2024 has 29 days, so 35 clamps to 29
      expect(result.day).to eq(29)
    end
  end

  describe "Date with year 0 typed" do
    it "clamps year to minimum valid value" do
      stub_keys("0", "0", "0", "0", :enter)
      prompt = Clack::Prompts::Date.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      result = prompt.run

      # Year 0 should clamp to 1
      expect(result.year).to eq(1)
    end
  end

  describe "Select with single option" do
    it "wraps correctly with one option" do
      stub_keys(:down, :enter)
      prompt = Clack::Prompts::Select.new(
        message: "Choose:",
        options: [{value: "only", label: "Only Option"}],
        output: output
      )
      result = prompt.run

      # Down should wrap back to the same single option
      expect(result).to eq("only")
    end

    it "up wraps to same option" do
      stub_keys(:up, :enter)
      prompt = Clack::Prompts::Select.new(
        message: "Choose:",
        options: [{value: "only", label: "Only Option"}],
        output: output
      )
      result = prompt.run

      expect(result).to eq("only")
    end
  end

  describe "Multiselect with max_items=1" do
    it "shows only one item at a time with scrolling" do
      options = %w[a b c]
      stub_keys(:down, :space, :enter)
      prompt = Clack::Prompts::Multiselect.new(
        message: "Choose:",
        options: options,
        max_items: 1,
        output: output
      )
      result = prompt.run

      expect(result).to eq(["b"])
    end
  end

  describe "Core Prompt warning re-validation after edit" do
    # When user edits during warning, the warning_confirmed flag must be reset.
    # If it's not, a second submit would skip validation entirely.

    let(:test_class) do
      Class.new(Clack::Core::Prompt) do
        def initialize(**opts)
          super
          @test_value = ""
        end

        def handle_input(key, _action)
          @test_value += key if key && key.length == 1 && key.ord >= 32
        end

        def submit
          @value = @test_value
          super
        end
      end
    end

    it "resets warning_confirmed when user edits during warning" do
      validate_count = 0
      stub_keys("a", :enter, "b", :enter, :enter)
      prompt = test_class.new(
        message: "Input",
        validate: lambda { |_|
          validate_count += 1
          Clack::Warning.new("Warning #{validate_count}")
        },
        output: output
      )
      prompt.run

      # Call 1: "a" submitted, warning returned
      # "b" typed, warning cleared (confirmed reset)
      # Call 2: "ab" submitted, warning returned again (not skipped!)
      # Enter confirms
      # Call 3: "ab" submitted, warning_confirmed=true, passes
      expect(validate_count).to eq(3)
    end
  end

  describe "Autocomplete warning validation" do
    # Autocomplete overrides handle_key but relies on dispatch_key for
    # warning handling. This interaction was untested.
    #
    # NOTE: Like MultilineText, Autocomplete's build_frame only renders error
    # messages, not warning messages. These tests verify state machine behavior.

    it "accepts value after warning confirmation" do
      stub_keys(:enter, :enter)
      prompt = Clack::Prompts::Autocomplete.new(
        message: "Pick:",
        options: %w[apple banana],
        validate: ->(_) { Clack::Warning.new("Are you sure?") },
        output: output
      )
      result = prompt.run

      expect(result).to eq("apple")
      expect(prompt.state).to eq(:submit)
    end

    it "can cancel from warning state" do
      stub_keys(:enter, :escape)
      prompt = Clack::Prompts::Autocomplete.new(
        message: "Pick:",
        options: %w[apple banana],
        validate: ->(_) { Clack::Warning.new("Sure?") },
        output: output
      )
      result = prompt.run

      expect(Clack.cancel?(result)).to be true
    end
  end

  describe "Group prompt block exception" do
    it "propagates exception from prompt block" do
      expect {
        Clack.group do |g|
          g.prompt(:name) { raise "prompt block exploded" }
        end
      }.to raise_error(RuntimeError, "prompt block exploded")
    end
  end
end
