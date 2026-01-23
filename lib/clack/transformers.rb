# frozen_string_literal: true

module Clack
  # Built-in transformers for normalizing user input.
  # Use these with the `transform:` option on prompts.
  #
  # Transforms are applied after validation passes, so you can validate
  # the raw input and transform it into a normalized form.
  #
  # @example Using built-in transformers
  #   Clack.text(message: "Name?", transform: Clack::Transformers.strip)
  #   Clack.text(message: "Code?", transform: Clack::Transformers.upcase)
  #   Clack.text(message: "Phone?", transform: Clack::Transformers.phone_us)
  #
  # @example Custom transformer
  #   Clack.text(
  #     message: "Amount?",
  #     transform: ->(v) { v.to_f.round(2) }
  #   )
  #
  # @example Combining with validation
  #   Clack.text(
  #     message: "Phone?",
  #     validate: Clack::Validators.format(/\A[\d\s\-().]+\z/, "Invalid phone number"),
  #     transform: Clack::Transformers.phone_us
  #   )
  #
  module Transformers
    class << self
      # Strip leading/trailing whitespace.
      #
      # @return [Proc] Transformer proc
      def strip
        ->(value) { value.to_s.strip }
      end

      # Convert to lowercase.
      #
      # @return [Proc] Transformer proc
      def downcase
        ->(value) { value.to_s.downcase }
      end

      # Convert to uppercase.
      #
      # @return [Proc] Transformer proc
      def upcase
        ->(value) { value.to_s.upcase }
      end

      # Squeeze multiple spaces into single space.
      #
      # @return [Proc] Transformer proc
      def squish
        ->(value) { value.to_s.strip.gsub(/\s+/, " ") }
      end

      # Parse as integer.
      #
      # @return [Proc] Transformer proc
      def to_integer
        ->(value) { value.to_s.to_i }
      end

      # Parse as float.
      #
      # @return [Proc] Transformer proc
      def to_float
        ->(value) { value.to_s.to_f }
      end

      # Format US phone number as (XXX) XXX-XXXX.
      # Extracts digits and formats them.
      #
      # @return [Proc] Transformer proc
      def phone_us
        lambda do |value|
          digits = value.to_s.gsub(/\D/, "")
          digits = digits[-10..] if digits.length > 10 # Take last 10 digits
          return value if digits.length != 10

          "(#{digits[0..2]}) #{digits[3..5]}-#{digits[6..9]}"
        end
      end

      # Format as credit card with spaces: XXXX XXXX XXXX XXXX.
      #
      # @return [Proc] Transformer proc
      def credit_card
        lambda do |value|
          digits = value.to_s.gsub(/\D/, "")
          digits.scan(/.{1,4}/).join(" ")
        end
      end

      # Format Social Security Number as XXX-XX-XXXX.
      #
      # @return [Proc] Transformer proc
      def ssn
        lambda do |value|
          digits = value.to_s.gsub(/\D/, "")
          return value if digits.length != 9

          "#{digits[0..2]}-#{digits[3..4]}-#{digits[5..8]}"
        end
      end

      # Combine multiple transformers, applied in order.
      #
      # @param transformers [Array<Proc>] Transformers to combine
      # @return [Proc] Combined transformer proc
      # :reek:NestedIterators :reek:UncommunicativeVariableName
      def chain(*transformers)
        ->(value) { transformers.reduce(value) { |val, transformer| transformer.call(val) } }
      end
    end
  end
end
