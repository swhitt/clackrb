# frozen_string_literal: true

module Clack
  # Built-in validators for common validation patterns.
  # Use these with the `validate:` option on prompts.
  #
  # @example Using built-in validators
  #   Clack.text(message: "Name?", validate: Clack::Validators.required)
  #   Clack.text(message: "Email?", validate: Clack::Validators.format(/@/, "Must be an email"))
  #   Clack.password(message: "Password?", validate: Clack::Validators.min_length(8))
  #
  # @example Combining validators
  #   Clack.text(
  #     message: "Username?",
  #     validate: Clack::Validators.combine(
  #       Clack::Validators.required("Username is required"),
  #       Clack::Validators.min_length(3, "Must be at least 3 characters"),
  #       Clack::Validators.max_length(20, "Must be at most 20 characters"),
  #       Clack::Validators.format(/\A[a-z0-9_]+\z/i, "Only letters, numbers, and underscores")
  #     )
  #   )
  #
  module Validators
    class << self
      # Validates that the input is not empty.
      #
      # @param message [String] Custom error message
      # @return [Proc] Validator proc
      def required(message = "This field is required")
        ->(value) { message if value.to_s.strip.empty? }
      end

      # Validates minimum length.
      #
      # @param length [Integer] Minimum length
      # @param message [String, nil] Custom error message (supports %d placeholder)
      # @return [Proc] Validator proc
      def min_length(length, message = nil)
        msg = message || "Must be at least #{length} characters"
        ->(value) { msg if value.to_s.length < length }
      end

      # Validates maximum length.
      #
      # @param length [Integer] Maximum length
      # @param message [String, nil] Custom error message
      # @return [Proc] Validator proc
      def max_length(length, message = nil)
        msg = message || "Must be at most #{length} characters"
        ->(value) { msg if value.to_s.length > length }
      end

      # Validates that input matches a regular expression.
      #
      # @param pattern [Regexp] Pattern to match
      # @param message [String] Error message if pattern doesn't match
      # @return [Proc] Validator proc
      def format(pattern, message = "Invalid format")
        ->(value) { message unless pattern.match?(value.to_s) }
      end

      # Validates that input is in a list of allowed values.
      #
      # @param allowed [Array] Allowed values
      # @param message [String, nil] Custom error message
      # @return [Proc] Validator proc
      def one_of(allowed, message = nil)
        msg = message || "Must be one of: #{allowed.join(", ")}"
        ->(value) { msg unless allowed.include?(value) }
      end

      # Validates that input is a valid integer.
      #
      # @param message [String] Error message
      # @return [Proc] Validator proc
      def integer(message = "Must be a number")
        ->(value) { message unless value.to_s.match?(/\A-?\d+\z/) }
      end

      # Validates that input is within a numeric range.
      # Note: Parses value as integer for comparison.
      #
      # @param range [Range] Allowed range
      # @param message [String, nil] Custom error message
      # @return [Proc] Validator proc
      def in_range(range, message = nil)
        msg = message || "Must be between #{range.first} and #{range.last}"
        lambda do |value|
          int_val = value.to_s.to_i
          msg unless range.cover?(int_val) && value.to_s.match?(/\A-?\d+\z/)
        end
      end

      # Combines multiple validators. Returns the first error message, or nil if all pass.
      #
      # @param validators [Array<Proc>] Validators to combine
      # @return [Proc] Combined validator proc
      def combine(*validators)
        ->(value) { first_failing_validation(validators, value) }
      end

      # Common email format validator.
      #
      # @param message [String] Error message
      # @return [Proc] Validator proc
      def email(message = "Must be a valid email address")
        format(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/, message)
      end

      # Common URL format validator.
      #
      # @param message [String] Error message
      # @return [Proc] Validator proc
      def url(message = "Must be a valid URL")
        format(%r{\Ahttps?://\S+\z}, message)
      end

      # Validates file path exists.
      #
      # @param message [String] Error message
      # @return [Proc] Validator proc
      def path_exists(message = "Path does not exist")
        ->(value) { message unless File.exist?(value.to_s) }
      end

      # Validates directory path exists.
      #
      # @param message [String] Error message
      # @return [Proc] Validator proc
      def directory_exists(message = "Directory does not exist")
        ->(value) { message unless File.directory?(value.to_s) }
      end

      private

      def first_failing_validation(validators, value)
        validators.each do |validator|
          result = validator.call(value)
          return result if result
        end
        nil
      end
    end
  end
end
