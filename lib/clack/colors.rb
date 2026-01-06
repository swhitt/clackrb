# frozen_string_literal: true

module Clack
  # ANSI color codes for terminal output styling.
  # Colors are automatically disabled when:
  # - Output is not a TTY (piped/redirected)
  # - NO_COLOR environment variable is set
  module Colors
    ENABLED = $stdout.tty? && !ENV["NO_COLOR"]

    class << self
      def enabled? = ENABLED

      # Foreground colors (standard)
      def gray(text) = wrap(text, "90")
      def cyan(text) = wrap(text, "36")
      def green(text) = wrap(text, "32")
      def yellow(text) = wrap(text, "33")
      def red(text) = wrap(text, "31")
      def blue(text) = wrap(text, "34")
      def magenta(text) = wrap(text, "35")
      def white(text) = wrap(text, "37")

      # Text styles
      def dim(text) = wrap(text, "2")
      def bold(text) = wrap(text, "1")
      def italic(text) = wrap(text, "3")
      def underline(text) = wrap(text, "4")
      def inverse(text) = wrap(text, "7")
      def strikethrough(text) = wrap(text, "9")
      def hidden(text) = wrap(text, "8")

      # Bright/vivid foreground colors (higher contrast)
      def bright_cyan(text) = wrap(text, "96")
      def bright_green(text) = wrap(text, "92")
      def bright_yellow(text) = wrap(text, "93")
      def bright_red(text) = wrap(text, "91")
      def bright_blue(text) = wrap(text, "94")
      def bright_magenta(text) = wrap(text, "95")
      def bright_white(text) = wrap(text, "97")

      private

      def wrap(text, code)
        return text.to_s unless enabled?

        "\e[#{code}m#{text}\e[0m"
      end
    end
  end
end
