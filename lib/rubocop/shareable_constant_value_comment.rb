# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for a `# shareable_constant_value: literal` magic comment at the top of the file.
      # If missing, it adds it automatically (with autocorrect) in the conventional location:
      #   - after an existing `# frozen_string_literal: true` comment (most common case)
      #   - after any other consecutive top-of-file magic comments (encoding, warn-indent, etc.)
      #   - after a shebang line if present
      #   - on line 1 otherwise
      #
      # This behaves almost exactly like Style/FrozenStringLiteralComment when that cop is configured
      # to always insert `# frozen_string_literal: true`.
      #
      # @example
      #   # bad (no shareable_constant_value comment)
      #   # frozen_string_literal: true
      #
      #   class Foo; end
      #
      #   # good
      #   # frozen_string_literal: true
      #   # shareable_constant_value: literal
      #
      #   class Foo; end
      #
      class ShareableConstantValueComment < Base
        include RangeHelp
        extend AutoCorrector

        MSG = "Add the magic comment `# shareable_constant_value: literal`."

        COMMENT = "# shareable_constant_value: literal\n"

        def on_new_investigation
          return if processed_source.lines.empty?  # Skip empty files
          return if shareable_constant_value_comment_present?

          add_offense(insertion_range, message: MSG) do |corrector|
            corrector.insert_before(insertion_range, COMMENT)
          end
        end

        private

        def shareable_constant_value_comment_present?
          processed_source.comments.any? do |comment|
            comment.text =~ /#\s*shareable_constant_value\s*:/ ||
              comment.text.strip == "# shareable_constant_value: literal"
          end
        end

        def first_line_range
          source_range(processed_source.buffer, 1, 0)
        end

        def insertion_range
          line_no = insertion_line_number
          source_range(processed_source.buffer, line_no, 0)
        end

        def insertion_line_number
          lines = processed_source.lines
          line_no = 1

          # Start after a shebang if one exists
          line_no = 2 if lines[0]&.start_with?("#!")

          # Walk past any consecutive top-of-file magic comments
          while (line = lines[line_no - 1]) &&
                line.strip.start_with?("#") &&
                magic_comment?(line)
            line_no += 1
          end

          line_no
        end

        def magic_comment?(line)
          stripped = line.strip
          stripped =~ /\A#\s*(?:(?:frozen_string_literal|encoding|coding|warn-indent|shareable_constant_value)\s*:|-\*-)/
        end
      end
    end
  end
end
