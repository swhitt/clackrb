# frozen_string_literal: true

module Clack
  # Built-in transformers for normalizing user input.
  # Use these with the `transform:` option on prompts.
  #
  # Transforms are applied after validation passes, so you can validate
  # the raw input and transform it into a normalized form.
  #
  # @example Using symbol shortcuts (preferred)
  #   Clack.text(message: "Name?", transform: :strip)
  #   Clack.text(message: "Code?", transform: :upcase)
  #
  # @example Using module methods
  #   Clack.text(message: "Name?", transform: Clack::Transformers.strip)
  #
  # @example Custom transformer
  #   Clack.text(
  #     message: "Amount?",
  #     transform: ->(v) { v.to_f.round(2) }
  #   )
  #
  # @example Chaining multiple transforms
  #   Clack.text(
  #     message: "Username?",
  #     transform: Clack::Transformers.chain(:strip, :downcase)
  #   )
  #
  module Transformers
    # Lookup table for symbol shortcuts
    REGISTRY = {}

    class << self
      # Resolve a transformer from a symbol, proc, or return as-is.
      # @param transformer [Symbol, Proc, nil] the transformer to resolve
      # @return [Proc, nil] the resolved transformer proc
      def resolve(transformer)
        case transformer
        when Symbol
          REGISTRY[transformer] || raise(ArgumentError, "Unknown transformer: #{transformer}")
        when Proc
          transformer
        when nil
          nil
        else
          raise ArgumentError, "Transform must be a Symbol or Proc, got #{transformer.class}"
        end
      end

      # Strip leading/trailing whitespace.
      # @return [Proc] Transformer proc
      def strip
        REGISTRY[:strip]
      end

      # Alias for strip (for JS developers).
      # @return [Proc] Transformer proc
      def trim
        REGISTRY[:trim]
      end

      # Convert to lowercase.
      # @return [Proc] Transformer proc
      def downcase
        REGISTRY[:downcase]
      end

      # Convert to uppercase.
      # @return [Proc] Transformer proc
      def upcase
        REGISTRY[:upcase]
      end

      # Capitalize first letter, lowercase rest.
      # @return [Proc] Transformer proc
      def capitalize
        REGISTRY[:capitalize]
      end

      # Capitalize first letter of each word.
      # @return [Proc] Transformer proc
      def titlecase
        REGISTRY[:titlecase]
      end

      # Strip and collapse whitespace to single spaces.
      # @return [Proc] Transformer proc
      def squish
        REGISTRY[:squish]
      end

      # Remove all whitespace.
      # @return [Proc] Transformer proc
      def compact
        REGISTRY[:compact]
      end

      # Parse as integer.
      # @return [Proc] Transformer proc
      def to_integer
        REGISTRY[:to_integer]
      end

      # Parse as float.
      # @return [Proc] Transformer proc
      def to_float
        REGISTRY[:to_float]
      end

      # Extract only digits.
      # @return [Proc] Transformer proc
      def digits_only
        REGISTRY[:digits_only]
      end

      # Combine multiple transformers, applied in order.
      # Accepts symbols or procs.
      #
      # @param transformers [Array<Symbol, Proc>] Transformers to combine
      # @return [Proc] Combined transformer proc
      #
      # @example
      #   Clack::Transformers.chain(:strip, :downcase)
      #   Clack::Transformers.chain(:strip, ->(v) { v.reverse })
      def chain(*transformers)
        resolved = transformers.map { |xform| resolve(xform) }
        ->(value) { resolved.reduce(value) { |val, xform| xform.call(val) } }
      end
    end

    # Register built-in transformers
    REGISTRY[:strip] = ->(value) { value.to_s.strip }
    REGISTRY[:trim] = REGISTRY[:strip]
    REGISTRY[:downcase] = ->(value) { value.to_s.downcase }
    REGISTRY[:upcase] = ->(value) { value.to_s.upcase }
    REGISTRY[:capitalize] = ->(value) { value.to_s.capitalize }
    REGISTRY[:titlecase] = ->(value) { value.to_s.gsub(/\b\w/, &:upcase) }
    REGISTRY[:squish] = ->(value) { value.to_s.strip.gsub(/\s+/, " ") }
    REGISTRY[:compact] = ->(value) { value.to_s.gsub(/\s+/, "") }
    REGISTRY[:to_integer] = ->(value) { value.to_s.to_i }
    REGISTRY[:to_float] = ->(value) { value.to_s.to_f }
    REGISTRY[:digits_only] = ->(value) { value.to_s.gsub(/\D/, "") }
  end
end
