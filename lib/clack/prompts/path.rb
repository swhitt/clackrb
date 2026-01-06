module Clack
  module Prompts
    class Path < Core::Prompt
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
        return unless Core::Settings.printable?(key)

        if Core::Settings.backspace?(key)
          return if @cursor == 0

          @value = @value[0...(@cursor - 1)] + @value[@cursor..]
          @cursor -= 1
        else
          @value = @value[0...@cursor] + key + @value[@cursor..]
          @cursor += 1
        end

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

        if @state == :error
          lines[-1] = "#{Colors.yellow(Symbols::S_BAR_END)}  #{Colors.yellow(@error_message)}\n"
        end

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
        entries = entries.select { |e| File.directory?(File.join(dir, e)) } if @only_directories
        entries = entries.select { |e| e.downcase.start_with?(prefix) } unless prefix.empty?
        entries.sort.first(@max_items * 2).map { |e| format_entry(dir, e) }
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

      def input_display
        return placeholder_display if @value.empty?

        value_with_cursor
      end

      def placeholder_display
        first = Colors.inverse(@root[0])
        rest = Colors.dim(@root[1..])
        "#{first}#{rest}"
      end

      def value_with_cursor
        return "#{@value}#{cursor_block}" if @cursor >= @value.length

        before = @value[0...@cursor]
        current = Colors.inverse(@value[@cursor])
        after = @value[(@cursor + 1)..]
        "#{before}#{current}#{after}"
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
