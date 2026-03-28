# frozen_string_literal: true

require "stringio"

module Clack
  # First-class test helpers for simulating prompt interactions.
  #
  # Works with RSpec, Minitest, or any test framework. Provides a DSL
  # for feeding keystrokes to prompts without a real terminal.
  #
  # @example Basic text prompt
  #   result = Clack::Testing.simulate(Clack.method(:text), message: "Name?") do |p|
  #     p.type("Alice")
  #     p.submit
  #   end
  #   assert_equal "Alice", result
  #
  # @example Select prompt
  #   result = Clack::Testing.simulate(Clack.method(:select), message: "Pick", options: %w[a b c]) do |p|
  #     p.down
  #     p.submit
  #   end
  #   assert_equal "b", result
  #
  # @example Multiselect
  #   result = Clack::Testing.simulate(Clack.method(:multiselect), message: "Pick", options: %w[a b c]) do |p|
  #     p.toggle      # select "a"
  #     p.down
  #     p.toggle      # select "b"
  #     p.submit
  #   end
  #   assert_equal %w[a b], result
  #
  # @example Cancellation
  #   result = Clack::Testing.simulate(Clack.method(:text), message: "Name?") do |p|
  #     p.cancel
  #   end
  #   assert Clack.cancel?(result)
  module Testing
    # Key constants matching what KeyReader returns
    KEYS = {
      enter: "\r",
      escape: "\e",
      ctrl_c: "\u0003",
      ctrl_d: "\u0004",
      up: "\e[A",
      down: "\e[B",
      right: "\e[C",
      left: "\e[D",
      backspace: "\u007F",
      space: " ",
      tab: "\t",
      shift_tab: "\e[Z"
    }.freeze

    # DSL for building a key sequence to feed to a prompt.
    class PromptDriver
      # @return [Array<String>] accumulated key sequence
      attr_reader :keys

      def initialize
        @keys = []
      end

      # Type a string of text character by character.
      # @param text [String] text to type
      def type(text)
        text.each_char { |char| @keys << char }
      end

      # Press Enter to submit.
      def submit = @keys << KEYS[:enter]

      # Press Escape to cancel.
      def cancel = @keys << KEYS[:escape]

      # Press arrow down.
      def down = @keys << KEYS[:down]

      # Press arrow up.
      def up = @keys << KEYS[:up]

      # Press arrow left.
      def left = @keys << KEYS[:left]

      # Press arrow right.
      def right = @keys << KEYS[:right]

      # Press Space (toggle selection in multiselect).
      def toggle = @keys << KEYS[:space]

      # Press Tab.
      def tab = @keys << KEYS[:tab]

      # Press Backspace.
      def backspace = @keys << KEYS[:backspace]

      # Press Ctrl+D (submit multiline text).
      def ctrl_d = @keys << KEYS[:ctrl_d]

      # Press an arbitrary key by name or character.
      # @param key [Symbol, String] key name (e.g. :escape) or raw character
      def key(key)
        @keys << (key.is_a?(Symbol) ? KEYS.fetch(key) : key)
      end
    end

    # A StringIO-like object that feeds keys from a queue.
    # Passed as the +input:+ parameter to prompts for testing.
    class KeyQueue
      def initialize(keys)
        @keys = keys
        @read_count = 0
      end

      def getc
        @read_count += 1
        raise "Too many reads (#{@read_count}) - possible infinite loop in test" if @read_count > 100

        @keys.shift || KEYS[:enter]
      end

      # Not a real TTY
      def tty? = false
    end

    class << self
      # Simulate a prompt interaction by feeding a predefined key sequence.
      #
      # @param prompt_method [Method, Proc] the Clack method to call (e.g. +Clack.method(:text)+)
      # @param kwargs [Hash] keyword arguments for the prompt
      # @yield [PromptDriver] block to define the interaction
      # @return [Object] the prompt result
      def simulate(prompt_method, **kwargs, &block)
        driver = PromptDriver.new
        block.call(driver)

        input = KeyQueue.new(driver.keys.dup)
        output = StringIO.new

        prompt_method.call(**kwargs, input: input, output: output)
      end

      # Capture the rendered output of a prompt simulation.
      # Returns both the result and the raw output string.
      #
      # @param prompt_method [Method, Proc] the Clack method to call
      # @param kwargs [Hash] keyword arguments for the prompt
      # @yield [PromptDriver] block to define the interaction
      # @return [Array(Object, String)] [result, output_string]
      def simulate_with_output(prompt_method, **kwargs, &block)
        driver = PromptDriver.new
        block.call(driver)

        input = KeyQueue.new(driver.keys.dup)
        output = StringIO.new

        result = prompt_method.call(**kwargs, input: input, output: output)
        [result, output.string]
      end
    end
  end
end
