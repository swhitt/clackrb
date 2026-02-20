# frozen_string_literal: true

require "date"

module Clack
  module Prompts
    # Date picker prompt with inline segmented input.
    #
    # Features:
    # - Three formats: :iso (YYYY-MM-DD), :us (MM/DD/YYYY), :eu (DD/MM/YYYY)
    # - Arrow key navigation between segments
    # - Up/down to increment/decrement values
    # - Direct digit typing with auto-advance
    # - Min/max date bounds validation
    #
    # @example Basic usage
    #   date = Clack.date(message: "Select a date")
    #
    # @example With bounds
    #   date = Clack.date(
    #     message: "When?",
    #     min: Date.today,
    #     max: Date.today + 365,
    #     format: :us
    #   )
    #
    class Date < Core::Prompt
      # Supported date format configurations mapping format symbol to segment order and separator.
      FORMATS = {
        iso: {order: [:year, :month, :day], sep: "-"},
        us: {order: [:month, :day, :year], sep: "/"},
        eu: {order: [:day, :month, :year], sep: "/"}
      }.freeze

      # Non-leap-year days per month (index 1-12; index 0 unused).
      DAYS_IN_MONTH = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze
      KEY_SHIFT_TAB = "\e[Z" # ANSI escape sequence for Shift+Tab

      # @param message [String] the prompt message
      # @param format [Symbol] date format (:iso, :us, :eu)
      # @param initial_value [Date, Time, String, nil] initial date value
      # @param min [Date, nil] minimum allowed date
      # @param max [Date, nil] maximum allowed date
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, format: :iso, initial_value: nil, min: nil, max: nil, **opts)
        super(message:, **opts)

        raise ArgumentError, "Unknown format: #{format}" unless FORMATS.key?(format)
        raise ArgumentError, "min must be before or equal to max" if min && max && min > max

        @format = format
        @min = min
        @max = max
        @segment = 0
        @input_buffer = ""

        init_date(initial_value)
      end

      protected

      def handle_input(key, action)
        case action
        when :left then move_segment(-1)
        when :right then move_segment(1)
        when :up then adjust_segment(1)
        when :down then adjust_segment(-1)
        else
          case key
          when "\t" then move_segment(1)
          when KEY_SHIFT_TAB then move_segment(-1)
          when /\A\d\z/ then handle_digit(key)
          end
        end
      end

      def submit
        @value = ::Date.new(@year, @month, @day)
        super
      rescue ArgumentError
        @error_message = friendly_date_error
        @state = :error
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << help_line
        lines << "#{active_bar}  #{date_display}\n"
        lines << "#{bar_end}\n" if %i[active initial].include?(@state)

        validation_lines = validation_message_lines
        if validation_lines.any?
          lines[-1] = validation_lines.first
          lines.concat(validation_lines[1..])
        end

        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        display_text = formatted_date
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(display_text)) : Colors.dim(display_text)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def init_date(initial)
        date = parse_initial(initial)
        date = clamp_to_bounds(date)
        @year = date.year
        @month = date.month
        @day = date.day
      end

      def parse_initial(initial)
        case initial
        when ::Date then initial
        when ::Time then initial.to_date
        when String then ::Date.parse(initial)
        else ::Date.today
        end
      rescue ::Date::Error
        ::Date.today
      end

      def clamp_to_bounds(date)
        return @min if @min && date < @min
        return @max if @max && date > @max

        date
      end

      # Enforce min/max bounds on the current @year/@month/@day components.
      # Constructs a temporary Date (after clamping day to valid range) and
      # writes back if the date falls outside the allowed bounds.
      def enforce_bounds
        return unless @min || @max

        clamp_day_to_month
        date = ::Date.new(@year, @month, @day)
        clamped = clamp_to_bounds(date)
        return if clamped == date

        @year = clamped.year
        @month = clamped.month
        @day = clamped.day
      end

      def move_segment(delta)
        commit_input_buffer
        @segment = (@segment + delta) % 3
        @input_buffer = ""
      end

      def adjust_segment(delta)
        commit_input_buffer
        @input_buffer = ""

        case current_segment_type
        when :year
          @year = (@year + delta).clamp(1, 9999)
          clamp_day_to_month
        when :month
          @month += delta
          @month = wrap_value(@month, 1, 12)
          clamp_day_to_month
        when :day
          max_day = days_in_month(@year, @month)
          @day = wrap_value(@day + delta, 1, max_day)
        end

        enforce_bounds
      end

      def wrap_value(val, min, max)
        return min if val > max
        return max if val < min

        val
      end

      def handle_digit(digit)
        @input_buffer += digit
        expected_length = (current_segment_type == :year) ? 4 : 2

        if @input_buffer.length >= expected_length
          commit_input_buffer
          move_segment(1) unless @segment == 2
        end
      end

      def commit_input_buffer
        return if @input_buffer.empty?

        value = @input_buffer.to_i
        @input_buffer = ""

        case current_segment_type
        when :year
          @year = value.clamp(1, 9999)
          clamp_day_to_month
        when :month
          @month = value.clamp(1, 12)
          clamp_day_to_month
        when :day
          @day = value.clamp(1, days_in_month(@year, @month))
        end

        enforce_bounds
      end

      def current_segment_type = FORMATS[@format][:order][@segment]

      def days_in_month(year, month)
        return 29 if month == 2 && leap_year?(year)

        DAYS_IN_MONTH[month]
      end

      def leap_year?(year) = ::Date.leap?(year)

      def clamp_day_to_month
        max_day = days_in_month(@year, @month)
        @day = max_day if @day > max_day
      end

      def formatted_date
        fmt = FORMATS[@format]
        fmt[:order].map { |type|
          case type
          when :year then @year.to_s.rjust(4, "0")
          when :month then @month.to_s.rjust(2, "0")
          when :day then @day.to_s.rjust(2, "0")
          end
        }.join(fmt[:sep])
      end

      def date_display
        fmt = FORMATS[@format]
        fmt[:order].each_with_index.map { |type, idx|
          text = segment_text_for(type)
          (idx == @segment) ? Colors.inverse(text) : text
        }.join(fmt[:sep])
      end

      def segment_text_for(type)
        showing_buffer = !@input_buffer.empty? && current_segment_type == type
        case type
        when :year
          showing_buffer ? @input_buffer.ljust(4, "_") : @year.to_s.rjust(4, "0")
        when :month
          showing_buffer ? @input_buffer.ljust(2, "_") : @month.to_s.rjust(2, "0")
        when :day
          showing_buffer ? @input_buffer.ljust(2, "_") : @day.to_s.rjust(2, "0")
        end
      end

      def friendly_date_error
        max_day = days_in_month(@year, @month)
        month_name = ::Date::MONTHNAMES[@month]

        if @day > max_day
          leap_note = (@month == 2 && !leap_year?(@year)) ? " (not a leap year)" : ""
          "#{month_name} #{@year} has #{max_day} days#{leap_note}"
        else
          "Invalid date"
        end
      end
    end
  end
end
