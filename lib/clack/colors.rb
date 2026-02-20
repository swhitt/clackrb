# frozen_string_literal: true

module Clack
  # ANSI color codes for terminal output styling.
  # Colors are automatically disabled when:
  # - Output is not a TTY (piped/redirected)
  # - NO_COLOR environment variable is set
  # - FORCE_COLOR environment variable forces colors on
  module Colors
    class << self
      def enabled?
        return true if ENV["FORCE_COLOR"] && ENV["FORCE_COLOR"] != "0"
        return false if ENV["NO_COLOR"]

        $stdout.tty?
      end

      # @!group Foreground Colors (standard)

      # Apply gray foreground color (ANSI 90).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def gray(text) = wrap(text, "90")

      # Apply cyan foreground color (ANSI 36).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def cyan(text) = wrap(text, "36")

      # Apply green foreground color (ANSI 32).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def green(text) = wrap(text, "32")

      # Apply yellow foreground color (ANSI 33).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def yellow(text) = wrap(text, "33")

      # Apply red foreground color (ANSI 31).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def red(text) = wrap(text, "31")

      # Apply blue foreground color (ANSI 34).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def blue(text) = wrap(text, "34")

      # Apply magenta foreground color (ANSI 35).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def magenta(text) = wrap(text, "35")

      # Apply white foreground color (ANSI 37).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def white(text) = wrap(text, "37")

      # @!endgroup

      # @!group Text Styles

      # Apply dim/faint style (ANSI 2).
      # @param text [#to_s] text to style
      # @return [String] ANSI-wrapped text
      def dim(text) = wrap(text, "2")

      # Apply bold style (ANSI 1).
      # @param text [#to_s] text to style
      # @return [String] ANSI-wrapped text
      def bold(text) = wrap(text, "1")

      # Apply italic style (ANSI 3).
      # @param text [#to_s] text to style
      # @return [String] ANSI-wrapped text
      def italic(text) = wrap(text, "3")

      # Apply underline style (ANSI 4).
      # @param text [#to_s] text to style
      # @return [String] ANSI-wrapped text
      def underline(text) = wrap(text, "4")

      # Apply inverse/reverse video style (ANSI 7).
      # @param text [#to_s] text to style
      # @return [String] ANSI-wrapped text
      def inverse(text) = wrap(text, "7")

      # Apply strikethrough style (ANSI 9).
      # @param text [#to_s] text to style
      # @return [String] ANSI-wrapped text
      def strikethrough(text) = wrap(text, "9")

      # Apply hidden/invisible style (ANSI 8).
      # @param text [#to_s] text to style
      # @return [String] ANSI-wrapped text
      def hidden(text) = wrap(text, "8")

      # @!endgroup

      # @!group Bright Foreground Colors (high contrast)

      # Apply bright cyan foreground color (ANSI 96).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def bright_cyan(text) = wrap(text, "96")

      # Apply bright green foreground color (ANSI 92).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def bright_green(text) = wrap(text, "92")

      # Apply bright yellow foreground color (ANSI 93).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def bright_yellow(text) = wrap(text, "93")

      # Apply bright red foreground color (ANSI 91).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def bright_red(text) = wrap(text, "91")

      # Apply bright blue foreground color (ANSI 94).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def bright_blue(text) = wrap(text, "94")

      # Apply bright magenta foreground color (ANSI 95).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def bright_magenta(text) = wrap(text, "95")

      # Apply bright white foreground color (ANSI 97).
      # @param text [#to_s] text to colorize
      # @return [String] ANSI-wrapped text
      def bright_white(text) = wrap(text, "97")

      # @!endgroup

      private

      def wrap(text, code)
        return text.to_s unless enabled?

        "\e[#{code}m#{text}\e[0m"
      end
    end
  end
end
