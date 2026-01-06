# frozen_string_literal: true

module Clack
  # Collects results from multiple prompts and handles cancellation gracefully.
  #
  # @example Basic usage
  #   result = Clack.group do |g|
  #     g.prompt(:name) { Clack.text(message: "Your name?") }
  #     g.prompt(:age) { Clack.text(message: "Your age?") }
  #   end
  #   # => { name: "Alice", age: "30" } or Clack::CANCEL
  #
  # @example With previous results
  #   result = Clack.group do |g|
  #     g.prompt(:name) { Clack.text(message: "Your name?") }
  #     g.prompt(:greeting) { |r| Clack.text(message: "Hello #{r[:name]}!") }
  #   end
  #
  class Group
    # @return [Hash] The collected results
    attr_reader :results

    def initialize(on_cancel: nil)
      @results = {}
      @prompts = []
      @on_cancel = on_cancel
    end

    # Define a prompt in the group.
    #
    # @param name [Symbol, String] The key for this result
    # @yield [results] Block that returns a prompt result
    # @yieldparam results [Hash] Previous results collected so far
    # @return [void]
    def prompt(name, &block)
      raise ArgumentError, "Block required for prompt :#{name}" unless block_given?

      @prompts << {name: name.to_sym, block: block}
    end

    # Run all prompts and collect results.
    #
    # @return [Hash, Clack::CANCEL] Results hash or CANCEL if user cancelled
    def run
      @prompts.each do |prompt_def|
        name = prompt_def[:name]
        block = prompt_def[:block]

        # Pass previous results to the block if it accepts an argument
        result = if block.arity == 0
          block.call
        else
          block.call(@results.dup.freeze)
        end

        if Clack.cancel?(result)
          @results[name] = :cancelled
          @on_cancel&.call(@results.dup.freeze)
          return CANCEL
        end

        @results[name] = result
      end

      @results
    end
  end

  class << self
    # Run a group of prompts and collect their results.
    #
    # If any prompt is cancelled, the entire group returns Clack::CANCEL.
    # The on_cancel callback receives partial results collected so far.
    #
    # @param on_cancel [Proc, nil] Callback when a prompt is cancelled
    # @yield [group] Block to define prompts
    # @yieldparam group [Clack::Group] The group builder
    # @return [Hash, Clack::CANCEL] Results hash or CANCEL
    #
    # @example
    #   result = Clack.group do |g|
    #     g.prompt(:name) { Clack.text(message: "Name?") }
    #     g.prompt(:confirm) { Clack.confirm(message: "Continue?") }
    #   end
    #
    #   if Clack.cancel?(result)
    #     Clack.cancel("Cancelled")
    #   else
    #     puts "Name: #{result[:name]}"
    #   end
    #
    def group(on_cancel: nil, &block)
      raise ArgumentError, "Block required for Clack.group" unless block_given?

      group = Group.new(on_cancel: on_cancel)
      block.call(group)
      group.run
    end
  end
end
