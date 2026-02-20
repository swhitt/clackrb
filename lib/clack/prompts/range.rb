# frozen_string_literal: true

module Clack
  module Prompts
    # Range/slider prompt for numeric selection.
    #
    # Displays a horizontal slider track. Navigate with arrow keys or vim
    # bindings. Press Enter to confirm.
    #
    # @example Basic usage
    #   level = Clack.range(message: "Volume", min: 0, max: 100, step: 5)
    #
    # @example With default value
    #   workers = Clack.range(
    #     message: "Concurrency",
    #     min: 1, max: 16,
    #     step: 1, default: 4
    #   )
    #
    class Range < Core::Prompt
      TRACK_WIDTH = 30
      TRACK_CHAR = "\u2501" # ━ (box drawings heavy horizontal)
      HANDLE_CHAR = "\u25CF" # ● (black circle)

      # @param message [String] the prompt message
      # @param min [Numeric] minimum value (default: 0)
      # @param max [Numeric] maximum value (default: 100)
      # @param step [Numeric] increment size (default: 1)
      # @param default [Numeric, nil] initial value (defaults to min)
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, min: 0, max: 100, step: 1, default: nil, **opts)
        super(message:, **opts)

        raise ArgumentError, "min must be less than max" if min >= max
        raise ArgumentError, "step must be positive" if step <= 0

        @min = min
        @max = max
        @step = step
        @value = clamp(default || min)
      end

      protected

      def handle_input(key, action)
        case action
        when :right, :up then adjust(@step)
        when :down, :left then adjust(-@step)
        end
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << help_line
        lines << "#{active_bar}  #{slider_display}\n"
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

        display = format_value(@value)
        styled = (@state == :cancel) ? Colors.strikethrough(Colors.dim(display)) : Colors.dim(display)
        lines << "#{bar}  #{styled}\n"

        lines.join
      end

      private

      def adjust(delta)
        @value = clamp(@value + delta)
      end

      def clamp(val)
        val = @min if val < @min
        val = @max if val > @max
        # Snap to step grid
        if @step != 0
          snapped = @min + (((val - @min).to_f / @step).round * @step)
          snapped = @max if snapped > @max
          snapped = @min if snapped < @min
          snapped
        else
          val
        end
      end

      def format_value(val)
        (val == val.to_i) ? val.to_i.to_s : val.to_s
      end

      def slider_display
        ratio = (@value - @min).to_f / (@max - @min)
        handle_pos = (ratio * TRACK_WIDTH).round.clamp(0, TRACK_WIDTH)

        left_track = TRACK_CHAR * handle_pos
        right_track = TRACK_CHAR * (TRACK_WIDTH - handle_pos)

        handle = Colors.cyan(HANDLE_CHAR)
        left = Colors.cyan(left_track)
        right = Colors.dim(right_track)

        "#{left}#{handle}#{right}  #{Colors.cyan(format_value(@value))}"
      end
    end
  end
end
