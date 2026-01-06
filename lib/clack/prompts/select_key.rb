module Clack
  module Prompts
    class SelectKey < Core::Prompt
      def initialize(message:, options:, **opts)
        super(message:, **opts)
        @options = normalize_options(options)
        @value = nil
      end

      protected

      def handle_key(key)
        return if terminal_state?

        action = Core::Settings.action?(key)

        case action
        when :cancel
          @state = :cancel
        else
          # Check if key matches any option
          opt = @options.find { |o| o[:key].downcase == key&.downcase }
          if opt
            @value = opt[:value]
            @state = :submit
          end
        end
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        @options.each do |opt|
          lines << "#{bar}  #{option_display(opt)}\n"
        end

        lines << "#{Colors.gray(Symbols::S_BAR_END)}\n"
        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        selected = @options.find { |o| o[:value] == @value }
        label = selected ? selected[:label] : ""
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(label)) : Colors.dim(label)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def normalize_options(options)
        options.map do |opt|
          {
            value: opt[:value],
            label: opt[:label] || opt[:value].to_s,
            key: opt[:key] || opt[:value].to_s[0],
            hint: opt[:hint]
          }
        end
      end

      def option_display(opt)
        key_display = Colors.cyan("[#{opt[:key]}]")
        hint = opt[:hint] ? " #{Colors.dim("(#{opt[:hint]})")}" : ""
        "#{key_display} #{opt[:label]}#{hint}"
      end
    end
  end
end
