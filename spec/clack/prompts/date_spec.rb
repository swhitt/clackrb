# frozen_string_literal: true

RSpec.describe Clack::Prompts::Date do
  let(:output) { StringIO.new }
  subject { described_class.new(message: "Select a date", output: output) }

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "renders message and accepts input" do
      stub_keys(:enter)
      result = subject.run

      expect(result).to be_a(Date)
      expect(output.string).to include("Select a date")
    end

    it "defaults to today's date" do
      stub_keys(:enter)
      result = subject.run

      expect(result).to eq(Date.today)
    end

    context "with initial value" do
      it "accepts Date object" do
        stub_keys(:enter)
        prompt = described_class.new(
          message: "Date?",
          initial_value: Date.new(2024, 6, 15),
          output: output
        )
        result = prompt.run

        expect(result).to eq(Date.new(2024, 6, 15))
      end

      it "accepts Time object" do
        stub_keys(:enter)
        prompt = described_class.new(
          message: "Date?",
          initial_value: Time.new(2024, 6, 15),
          output: output
        )
        result = prompt.run

        expect(result).to eq(Date.new(2024, 6, 15))
      end

      it "accepts String" do
        stub_keys(:enter)
        prompt = described_class.new(
          message: "Date?",
          initial_value: "2024-06-15",
          output: output
        )
        result = prompt.run

        expect(result).to eq(Date.new(2024, 6, 15))
      end

      it "falls back to today for invalid string" do
        stub_keys(:enter)
        prompt = described_class.new(
          message: "Date?",
          initial_value: "not-a-date",
          output: output
        )
        result = prompt.run

        expect(result).to eq(Date.today)
      end
    end
  end

  describe "format display" do
    it "displays ISO format (YYYY-MM-DD)" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      prompt.run

      expect(output.string).to include("2024-06-15")
    end

    it "displays US format (MM/DD/YYYY)" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Date?",
        format: :us,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      prompt.run

      # Final display shows MM/DD/YYYY
      expect(output.string).to include("06/15/2024")
    end

    it "displays EU format (DD/MM/YYYY)" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Date?",
        format: :eu,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      prompt.run

      expect(output.string).to include("15/06/2024")
    end

    it "raises for unknown format" do
      expect {
        described_class.new(message: "Date?", format: :invalid, output: output)
      }.to raise_error(ArgumentError, /Unknown format/)
    end
  end

  describe "segment navigation" do
    it "moves to next segment with tab" do
      stub_keys(:tab, :up, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 1, 15),
        output: output
      )
      result = prompt.run

      # Started on year, tab to month, up increments month
      expect(result.month).to eq(2)
    end

    it "moves to previous segment with shift+tab" do
      stub_keys(:tab, :shift_tab, :up, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 1, 15),
        output: output
      )
      result = prompt.run

      # Year -> month -> year, up increments year
      expect(result.year).to eq(2025)
    end

    it "moves with arrow keys" do
      stub_keys(:right, :right, :down, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 1, 15),
        output: output
      )
      result = prompt.run

      # Year -> month -> day, down decrements day
      expect(result.day).to eq(14)
    end

    it "wraps at segment boundaries" do
      stub_keys(:left, :down, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 1, 15),
        output: output
      )
      result = prompt.run

      # Left from first segment wraps to last (day), down decrements day
      expect(result.day).to eq(14)
    end
  end

  describe "value adjustment" do
    it "increments year with up" do
      stub_keys(:up, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      result = prompt.run

      expect(result).to eq(Date.new(2025, 6, 15))
    end

    it "decrements year with down" do
      stub_keys(:down, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      result = prompt.run

      expect(result).to eq(Date.new(2023, 6, 15))
    end

    it "wraps month from 12 to 1" do
      stub_keys(:tab, :up, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 12, 15),
        output: output
      )
      result = prompt.run

      expect(result.month).to eq(1)
    end

    it "wraps month from 1 to 12" do
      stub_keys(:tab, :down, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 1, 15),
        output: output
      )
      result = prompt.run

      expect(result.month).to eq(12)
    end

    it "wraps day correctly for month" do
      stub_keys(:tab, :tab, :up, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 1, 31),
        output: output
      )
      result = prompt.run

      # Day wraps from 31 to 1 for January
      expect(result.day).to eq(1)
    end
  end

  describe "digit input" do
    it "types digits into year segment" do
      stub_keys("2", "0", "2", "5", :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      result = prompt.run

      expect(result.year).to eq(2025)
    end

    it "auto-advances after complete segment (year)" do
      stub_keys("2", "0", "2", "5", "0", "7", :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      result = prompt.run

      # 2025 for year, auto-advance, 07 for month
      expect(result.year).to eq(2025)
      expect(result.month).to eq(7)
    end

    it "auto-advances after complete segment (month)" do
      stub_keys(:tab, "0", "3", "2", "0", :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      result = prompt.run

      # Tab to month, type 03, auto-advance, type 20 for day
      expect(result.month).to eq(3)
      expect(result.day).to eq(20)
    end

    it "clamps invalid values" do
      stub_keys(:tab, "1", "5", :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      result = prompt.run

      # Month 15 is clamped to 12
      expect(result.month).to eq(12)
    end
  end

  describe "day clamping" do
    it "clamps day when month changes to shorter month" do
      stub_keys(:tab, :up, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 1, 31),
        output: output
      )
      result = prompt.run

      # January 31 -> February (29 days in 2024 leap year)
      expect(result).to eq(Date.new(2024, 2, 29))
    end

    it "clamps day for non-leap year February" do
      stub_keys(:tab, :up, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2023, 1, 31),
        output: output
      )
      result = prompt.run

      # January 31 -> February 28 (2023 is not a leap year)
      expect(result).to eq(Date.new(2023, 2, 28))
    end

    it "handles leap year correctly" do
      stub_keys(:tab, :tab, :up, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 2, 28),
        output: output
      )
      result = prompt.run

      # 2024 is leap year, can have Feb 29
      expect(result).to eq(Date.new(2024, 2, 29))
    end

    it "handles year change affecting leap year" do
      stub_keys(:down, :enter)
      prompt = described_class.new(
        message: "Date?",
        format: :iso,
        initial_value: Date.new(2024, 2, 29),
        output: output
      )
      result = prompt.run

      # 2024 is leap, 2023 is not - day clamps to 28
      expect(result).to eq(Date.new(2023, 2, 28))
    end
  end

  describe "min/max bounds" do
    it "clamps initial date to min" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Date?",
        initial_value: Date.new(2024, 1, 1),
        min: Date.new(2024, 6, 1),
        output: output
      )
      result = prompt.run

      expect(result).to eq(Date.new(2024, 6, 1))
    end

    it "clamps initial date to max" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Date?",
        initial_value: Date.new(2024, 12, 31),
        max: Date.new(2024, 6, 30),
        output: output
      )
      result = prompt.run

      expect(result).to eq(Date.new(2024, 6, 30))
    end

    it "raises if min > max" do
      expect {
        described_class.new(
          message: "Date?",
          min: Date.new(2024, 12, 1),
          max: Date.new(2024, 1, 1),
          output: output
        )
      }.to raise_error(ArgumentError, /min must be before/)
    end

    context "runtime enforcement with arrow keys" do
      it "prevents arrowing year below min" do
        stub_keys(:down, :enter)
        prompt = described_class.new(
          message: "Date?",
          format: :iso,
          initial_value: Date.new(2024, 6, 15),
          min: Date.new(2024, 3, 1),
          output: output
        )
        result = prompt.run

        # Year 2023 would be below min (2024-03-01), so it clamps back
        expect(result).to eq(Date.new(2024, 3, 1))
      end

      it "prevents arrowing year above max" do
        stub_keys(:up, :enter)
        prompt = described_class.new(
          message: "Date?",
          format: :iso,
          initial_value: Date.new(2024, 6, 15),
          max: Date.new(2024, 12, 31),
          output: output
        )
        result = prompt.run

        # Year 2025 would exceed max (2024-12-31), so it clamps back
        expect(result).to eq(Date.new(2024, 12, 31))
      end

      it "prevents arrowing month below min" do
        stub_keys(:tab, :down, :enter)
        prompt = described_class.new(
          message: "Date?",
          format: :iso,
          initial_value: Date.new(2024, 6, 15),
          min: Date.new(2024, 6, 1),
          output: output
        )
        result = prompt.run

        # Month 5 (May) would be below min (June 1), so it clamps
        expect(result).to eq(Date.new(2024, 6, 1))
      end

      it "prevents arrowing month above max" do
        stub_keys(:tab, :up, :enter)
        prompt = described_class.new(
          message: "Date?",
          format: :iso,
          initial_value: Date.new(2024, 6, 15),
          max: Date.new(2024, 6, 30),
          output: output
        )
        result = prompt.run

        # Month 7 (July) would exceed max (June 30), so it clamps
        expect(result).to eq(Date.new(2024, 6, 30))
      end

      it "prevents arrowing day below min" do
        stub_keys(:tab, :tab, :down, :enter)
        prompt = described_class.new(
          message: "Date?",
          format: :iso,
          initial_value: Date.new(2024, 6, 10),
          min: Date.new(2024, 6, 10),
          output: output
        )
        result = prompt.run

        # Day 9 would be below min (June 10), so it clamps
        expect(result).to eq(Date.new(2024, 6, 10))
      end

      it "prevents arrowing day above max" do
        stub_keys(:tab, :tab, :up, :enter)
        prompt = described_class.new(
          message: "Date?",
          format: :iso,
          initial_value: Date.new(2024, 6, 15),
          max: Date.new(2024, 6, 15),
          output: output
        )
        result = prompt.run

        # Day 16 would exceed max (June 15), so it clamps
        expect(result).to eq(Date.new(2024, 6, 15))
      end

      it "allows navigation within bounds" do
        stub_keys(:tab, :tab, :up, :up, :enter)
        prompt = described_class.new(
          message: "Date?",
          format: :iso,
          initial_value: Date.new(2024, 6, 10),
          min: Date.new(2024, 6, 1),
          max: Date.new(2024, 6, 30),
          output: output
        )
        result = prompt.run

        # Day 10 -> 11 -> 12, all within bounds
        expect(result).to eq(Date.new(2024, 6, 12))
      end

      it "clamps digit input that exceeds max" do
        # Tab to month, type "12" which auto-advances, then enter
        stub_keys(:tab, "1", "2", :enter)
        prompt = described_class.new(
          message: "Date?",
          format: :iso,
          initial_value: Date.new(2024, 6, 15),
          max: Date.new(2024, 9, 30),
          output: output
        )
        result = prompt.run

        # Month 12 exceeds max (Sept 30), so clamps to max
        expect(result).to eq(Date.new(2024, 9, 30))
      end

      it "clamps digit input that goes below min" do
        # Tab to month, type "01" which auto-advances, then enter
        stub_keys(:tab, "0", "1", :enter)
        prompt = described_class.new(
          message: "Date?",
          format: :iso,
          initial_value: Date.new(2024, 6, 15),
          min: Date.new(2024, 3, 1),
          output: output
        )
        result = prompt.run

        # Month 01 (Jan) is below min (March 1), so clamps to min
        expect(result).to eq(Date.new(2024, 3, 1))
      end
    end
  end

  describe "validation" do
    it "validates with custom validator" do
      # 2024-01-01 is Monday, valid; we just submit immediately
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Date?",
        initial_value: Date.new(2024, 1, 1),
        validate: ->(d) { "No weekends!" if d.saturday? || d.sunday? },
        output: output
      )
      result = prompt.run

      expect(result).to eq(Date.new(2024, 1, 1))
    end

    it "shows validation error" do
      # 2024-01-06 is Saturday, invalid; press enter, see error, then nav to day, up twice to Monday
      stub_keys(:enter, :tab, :tab, :up, :up, :enter)
      prompt = described_class.new(
        message: "Date?",
        initial_value: Date.new(2024, 1, 6), # Saturday
        validate: ->(d) { "No weekends!" if d.saturday? || d.sunday? },
        output: output
      )
      result = prompt.run

      expect(output.string).to include("No weekends!")
      # Day 6 (Sat) -> 7 (Sun) -> 8 (Mon)
      expect(result).to eq(Date.new(2024, 1, 8))
    end
  end

  describe "cancellation" do
    it "renders cancelled value in output" do
      stub_keys(:escape)
      prompt = described_class.new(
        message: "Date?",
        initial_value: Date.new(2024, 6, 15),
        output: output
      )
      result = prompt.run

      expect(Clack.cancel?(result)).to be true
      expect(output.string).to include("2024")
    end
  end

  describe "warning validation" do
    let(:warning_validator) { ->(d) { Clack::Warning.new("Are you sure about this date?") if d == Date.new(2024, 6, 15) } }

    it "shows warning and allows confirmation" do
      stub_keys(:enter, :enter)
      prompt = described_class.new(
        message: "Date?",
        initial_value: Date.new(2024, 6, 15),
        validate: warning_validator,
        output: output
      )
      result = prompt.run

      expect(result).to eq(Date.new(2024, 6, 15))
      expect(output.string).to include("Are you sure about this date?")
    end

    it "can cancel from warning state" do
      stub_keys(:enter, :escape)
      prompt = described_class.new(
        message: "Date?",
        initial_value: Date.new(2024, 6, 15),
        validate: warning_validator,
        output: output
      )
      result = prompt.run

      expect(Clack.cancel?(result)).to be true
    end

    it "clears warning on edit" do
      stub_keys(:enter, :up, :enter)
      prompt = described_class.new(
        message: "Date?",
        initial_value: Date.new(2024, 6, 15),
        validate: warning_validator,
        output: output
      )
      result = prompt.run

      # Changed year to 2025, no longer matches warning condition
      expect(result).to eq(Date.new(2025, 6, 15))
    end
  end
end
