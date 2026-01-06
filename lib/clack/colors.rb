# frozen_string_literal: true

module Clack
  module Colors
    ENABLED = $stdout.tty? && !ENV["NO_COLOR"]

    class << self
      def enabled? = ENABLED

      def gray(text) = wrap(text, "90")
      def cyan(text) = wrap(text, "36")
      def green(text) = wrap(text, "32")
      def yellow(text) = wrap(text, "33")
      def red(text) = wrap(text, "31")
      def blue(text) = wrap(text, "34")
      def magenta(text) = wrap(text, "35")
      def dim(text) = wrap(text, "2")
      def bold(text) = wrap(text, "1")
      def inverse(text) = wrap(text, "7")
      def strikethrough(text) = wrap(text, "9")
      def hidden(text) = wrap(text, "8")

      private

      def wrap(text, code)
        return text.to_s unless enabled?

        "\e[#{code}m#{text}\e[0m"
      end
    end
  end
end
