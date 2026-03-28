# frozen_string_literal: true

RSpec.describe Clack::Core::SelectionManager do
  let(:test_class) do
    Class.new do
      include Clack::Core::SelectionManager

      attr_accessor :selected, :required, :state, :error_message, :value

      def initialize(selected: Set.new, required: false)
        @selected = selected
        @required = required
        @state = :active
        @error_message = nil
        @value = []
      end
    end
  end

  let(:options) do
    [
      {value: "a", label: "Apple"},
      {value: "b", label: "Banana"},
      {value: "c", label: "Cherry"}
    ]
  end

  describe "#toggle_value" do
    subject { test_class.new }

    it "adds a value when not present" do
      subject.toggle_value("a")

      expect(subject.selected).to include("a")
    end

    it "removes a value when already present" do
      subject.selected = Set.new(["a"])

      subject.toggle_value("a")

      expect(subject.selected).not_to include("a")
    end

    it "toggles multiple values independently" do
      subject.toggle_value("a")
      subject.toggle_value("b")

      expect(subject.selected).to contain_exactly("a", "b")
    end

    it "only removes the toggled value, leaving others" do
      subject.selected = Set.new(["a", "b"])

      subject.toggle_value("a")

      expect(subject.selected).to contain_exactly("b")
    end
  end

  describe "#validate_selection" do
    context "when required and selection is empty" do
      subject { test_class.new(required: true) }

      it "returns false" do
        expect(subject.validate_selection).to be false
      end

      it "sets state to :error" do
        subject.validate_selection

        expect(subject.state).to eq(:error)
      end

      it "sets an error message mentioning space and enter" do
        subject.validate_selection

        expect(subject.error_message).to include("Please select at least one option")
      end
    end

    context "when required and selection is present" do
      subject { test_class.new(selected: Set.new(["a"]), required: true) }

      it "returns true" do
        expect(subject.validate_selection).to be true
      end

      it "does not change state" do
        subject.validate_selection

        expect(subject.state).to eq(:active)
      end
    end

    context "when not required and selection is empty" do
      subject { test_class.new(required: false) }

      it "returns true" do
        expect(subject.validate_selection).to be true
      end

      it "does not set an error message" do
        subject.validate_selection

        expect(subject.error_message).to be_nil
      end
    end
  end

  describe "#update_selection_value" do
    subject { test_class.new(selected: Set.new(["a", "b"])) }

    it "converts @selected to an array in @value" do
      subject.update_selection_value

      expect(subject.value).to contain_exactly("a", "b")
    end

    it "sets @value to empty array when nothing selected" do
      subject.selected = Set.new

      subject.update_selection_value

      expect(subject.value).to eq([])
    end
  end

  describe "#selected_labels" do
    it "returns comma-separated labels for selected values" do
      subject = test_class.new(selected: Set.new(["a", "c"]))

      result = subject.selected_labels(options)

      expect(result).to include("Apple")
      expect(result).to include("Cherry")
      expect(result).not_to include("Banana")
    end

    it "returns empty string when nothing is selected" do
      subject = test_class.new

      expect(subject.selected_labels(options)).to eq("")
    end

    it "returns single label without comma when one item selected" do
      subject = test_class.new(selected: Set.new(["b"]))

      expect(subject.selected_labels(options)).to eq("Banana")
    end

    it "preserves option order from all_options, not selection order" do
      subject = test_class.new(selected: Set.new(["c", "a"]))

      expect(subject.selected_labels(options)).to eq("Apple, Cherry")
    end
  end
end
