# frozen_string_literal: true

RSpec.describe Clack::Prompts::GroupMultiselect do
  let(:output) { StringIO.new }
  let(:options) do
    [
      {
        label: "Frontend",
        options: [
          {value: "react", label: "React"},
          {value: "vue", label: "Vue"}
        ]
      },
      {
        label: "Backend",
        options: [
          {value: "rails", label: "Rails"},
          {value: "sinatra", label: "Sinatra"}
        ]
      }
    ]
  end
  subject { described_class.new(message: "Select:", options: options, output: output) }

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "requires at least one selection by default" do
      stub_keys(:enter, :space, :enter)
      result = subject.run

      expect(result).to eq(["react"])
    end

    it "shows error when no selection and required" do
      stub_keys(:enter, :space, :enter)
      subject.run

      expect(output.string).to include("select at least one")
    end

    it "allows empty selection when not required" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Select:",
        options: options,
        required: false,
        output: output
      )
      result = prompt.run

      expect(result).to eq([])
    end

    it "space toggles selection" do
      stub_keys(:space, :down, :space, :enter)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      result = prompt.run

      expect(result).to contain_exactly("react", "vue")
    end

    it "space deselects already selected" do
      stub_keys(:space, :space, :down, :space, :enter)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["vue"])
    end

    it "down arrow moves cursor" do
      stub_keys(:down, :space, :enter)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["vue"])
    end

    it "up arrow moves cursor" do
      stub_keys(:down, :down, :up, :space, :enter)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["vue"])
    end

    it "wraps from last to first" do
      stub_keys(:down, :down, :down, :down, :space, :enter)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["react"])
    end

    it "wraps from first to last" do
      stub_keys(:up, :space, :enter)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["sinatra"])
    end

    it "respects initial_values" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Select:",
        options: options,
        initial_values: %w[vue rails],
        output: output
      )
      result = prompt.run

      expect(result).to contain_exactly("vue", "rails")
    end

    it "handles simple value options in groups" do
      simple_options = [
        {
          label: "Colors",
          options: %w[red blue green]
        }
      ]
      stub_keys(:space, :enter)
      prompt = described_class.new(
        message: "Select:",
        options: simple_options,
        output: output
      )
      result = prompt.run

      expect(result).to eq(["red"])
    end

    it "handles group label key" do
      options_with_group_key = [
        {
          group: "Frontend",
          options: [{value: "react", label: "React"}]
        }
      ]
      stub_keys(:space, :enter)
      prompt = described_class.new(
        message: "Select:",
        options: options_with_group_key,
        output: output
      )
      result = prompt.run

      expect(result).to eq(["react"])
      expect(output.string).to include("Frontend")
    end

    it "skips disabled options when navigating" do
      options_with_disabled = [
        {
          label: "Options",
          options: [
            {value: "a", label: "A", disabled: true},
            {value: "b", label: "B"},
            {value: "c", label: "C"}
          ]
        }
      ]
      # Navigate down to skip disabled option, toggle b, down, toggle c
      stub_keys(:down, :space, :down, :space, :enter)
      prompt = described_class.new(
        message: "Select:",
        options: options_with_disabled,
        output: output
      )
      result = prompt.run

      expect(result).to contain_exactly("b", "c")
    end

    it "cannot toggle disabled options" do
      options_with_disabled = [
        {
          label: "Options",
          options: [
            {value: "a", label: "A"},
            {value: "b", label: "B", disabled: true},
            {value: "c", label: "C"}
          ]
        }
      ]
      stub_keys(:space, :down, :space, :enter)
      prompt = described_class.new(
        message: "Select:",
        options: options_with_disabled,
        output: output
      )
      result = prompt.run

      # b is disabled and skipped
      expect(result).to contain_exactly("a", "c")
    end

    it "shows selected labels in final frame" do
      stub_keys(:space, :down, :space, :enter)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      prompt.run

      expect(output.string).to include("React")
      expect(output.string).to include("Vue")
    end

    it "clears error state on action" do
      stub_keys(:enter, :space, :enter)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      prompt.run

      expect(prompt.state).to eq(:submit)
    end

    it "shows strikethrough on cancel" do
      stub_keys(:space, :escape)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      prompt.run

      expect(output.string).to include(Clack::Symbols::S_STEP_CANCEL)
    end

    it "handles all options disabled" do
      all_disabled = [
        {
          label: "Options",
          options: [
            {value: "a", label: "A", disabled: true},
            {value: "b", label: "B", disabled: true}
          ]
        }
      ]
      stub_keys(:down, :up, :escape)
      prompt = described_class.new(
        message: "Select:",
        options: all_disabled,
        required: false,
        output: output
      )
      result = prompt.run

      expect(Clack.cancel?(result)).to be true
    end

    it "renders group labels in output" do
      stub_keys(:space, :enter)
      prompt = described_class.new(message: "Select:", options: options, output: output)
      prompt.run

      expect(output.string).to include("Frontend")
      expect(output.string).to include("Backend")
    end

    it "renders message in output" do
      stub_keys(:space, :enter)
      prompt = described_class.new(message: "Select features:", options: options, output: output)
      prompt.run

      expect(output.string).to include("Select features:")
    end

    describe "cursor_at option" do
      it "starts cursor at specified value" do
        stub_keys(:space, :enter)
        prompt = described_class.new(
          message: "Select:",
          options: options,
          cursor_at: "rails",
          output: output
        )
        result = prompt.run

        expect(result).to eq(["rails"])
      end
    end

    describe "selectable_groups option" do
      it "allows toggling entire groups when true" do
        stub_keys(:space, :enter)
        prompt = described_class.new(
          message: "Select:",
          options: options,
          selectable_groups: true,
          output: output
        )
        result = prompt.run

        # Toggling the Frontend group should select both react and vue
        expect(result).to contain_exactly("react", "vue")
      end

      it "skips group headers when navigating when false" do
        stub_keys(:down, :space, :enter)
        prompt = described_class.new(
          message: "Select:",
          options: options,
          selectable_groups: false,
          output: output
        )
        result = prompt.run

        # First down should go to vue (second option)
        expect(result).to eq(["vue"])
      end

      it "shows checkbox on groups when selectable" do
        stub_keys(:space, :enter)
        prompt = described_class.new(
          message: "Select:",
          options: options,
          selectable_groups: true,
          output: output
        )
        prompt.run

        # Group line should have checkbox symbol
        expect(output.string).to include(Clack::Symbols::S_CHECKBOX_SELECTED)
      end
    end

    describe "group_spacing option" do
      it "adds spacing between groups" do
        stub_keys(:space, :enter)
        prompt = described_class.new(
          message: "Select:",
          options: options,
          group_spacing: 1,
          output: output
        )
        prompt.run

        # Should have extra bar lines for spacing
        bar_count = output.string.scan(/#{Regexp.escape(Clack::Symbols::S_BAR)}/o).length
        expect(bar_count).to be > 6 # More than without spacing
      end
    end
  end
end
