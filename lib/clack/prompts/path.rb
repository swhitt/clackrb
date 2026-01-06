# frozen_string_literal: true

module Clack
  module Prompts
    class Path < Core::Prompt
      include Core::TextInputHelper

      def initialize(message:, root: ".", only_directories: false, max_items: 5, **opts)
        super(message:, **opts)
        @root = File.expand_path(root)
        @only_directories = only_directories
        @max_items = max_items
        @value = ""
        @cursor = 0
        @selected_index = 0
        @scroll_offset = 0
        @suggestions = []
        update_suggestions
      end

      protected

      def handle_key(key)
        return if terminal_state?

        @state = :active if @state == :error
        action = Core::Settings.action?(key)

        case action
        when :cancel
          @state = :cancel
        when :enter
          submit_selection
        when :up
          move_selection(-1)
        when :down
          move_selection(1)
        else
          # Tab to autocomplete
          if key == "\t" && !@suggestions.empty?
            autocomplete_selection
          else
            handle_text_input(key)
          end
        end
      end

      def handle_text_input(key)
        return unless super

        @selected_index = 0
        @scroll_offset = 0
        update_suggestions
      end

      def autocomplete_selection
        return if @suggestions.empty?

        @value = @suggestions[@selected_index]
        @cursor = @value.length
        update_suggestions
      end

      def submit_selection
        path = @value.empty? ? @root : resolve_path(@value)

        if @validate
          result = @validate.call(path)
          if result
            @error_message = result.is_a?(Exception) ? result.message : result.to_s
            @state = :error
            return
          end
        end

        @value = path
        @state = :submit
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << "#{active_bar}  #{input_display}\n"

        visible_suggestions.each_with_index do |path, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{bar}  #{suggestion_display(path, actual_idx == @selected_index)}\n"
        end

        lines << "#{bar_end}\n"

        lines[-1] = "#{Colors.yellow(Symbols::S_BAR_END)}  #{Colors.yellow(@error_message)}\n" if @state == :error

        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(@value)) : Colors.dim(@value)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def update_suggestions
        base_path = resolve_path(@value)
        search_dir = File.directory?(base_path) ? base_path : File.dirname(base_path)
        prefix = File.directory?(base_path) ? "" : File.basename(base_path).downcase

        @suggestions = list_entries(search_dir, prefix)
      rescue SystemCallError
        @suggestions = []
      end

      def list_entries(dir, prefix)
        return [] unless File.directory?(dir)

        entries = Dir.entries(dir) - [".", ".."]
        entries = entries.select { |entry| File.directory?(File.join(dir, entry)) } if @only_directories
        entries = entries.select { |entry| entry.downcase.start_with?(prefix) } unless prefix.empty?
        entries.sort.first(@max_items * 2).map { |entry| format_entry(dir, entry) }
      end

      def format_entry(dir, entry)
        full_path = File.join(dir, entry)
        path = full_path.start_with?(@root) ? full_path.sub(@root, ".") : full_path
        path += "/" if File.directory?(full_path)
        path
      end

      def resolve_path(input)
        return @root if input.empty?

        if input.start_with?("/")
          input
        elsif input.start_with?("~")
          File.expand_path(input)
        else
          File.join(@root, input)
        end
      end

      def visible_suggestions
        return @suggestions if @suggestions.length <= @max_items

        @suggestions[@scroll_offset, @max_items]
      end

      def move_selection(delta)
        return if @suggestions.empty?

        @selected_index = (@selected_index + delta) % @suggestions.length
        update_scroll
      end

      def update_scroll
        return unless @suggestions.length > @max_items

        if @selected_index < @scroll_offset
          @scroll_offset = @selected_index
        elsif @selected_index >= @scroll_offset + @max_items
          @scroll_offset = @selected_index - @max_items + 1
        end
      end

      # Override to use @root as placeholder
      def placeholder_display
        return "" if @root.empty?

        first = Colors.inverse(@root[0])
        rest = Colors.dim(@root[1..])
        "#{first}#{rest}"
      end

      def suggestion_display(path, active)
        icon = path.end_with?("/") ? Symbols::S_FOLDER : Symbols::S_FILE
        if active
          "#{Colors.cyan(icon)} #{path}"
        else
          "#{Colors.dim(icon)} #{Colors.dim(path)}"
        end
      end
    end
  end
end
