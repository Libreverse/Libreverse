# lib/haml_lint/linter/hardcoded_string_linter.rb
# frozen_string_literal: true

require "yaml"
require "haml_lint/linter"

module HamlLint
  # Lints hard-coded text that should be translated via I18n
  class HardcodedStringLinter < Linter
    include LinterRegistry

    MSG = 'Hardcoded string "%s" should use i18n'
    NON_TEXT_TAGS = Set.new(%w[script style xmp iframe noembed noframes listing])
    NO_TRANSLATION_NEEDED = Set.new(%w[& < > " © ® ™ … — • " " ' ' ← → ↓ ↑ × » «]).freeze

    # ------------------------------------------------------------------
    #                         Class State
    # ------------------------------------------------------------------
    @master_yaml = nil # Hash representation of en.yml across run

    class << self
      attr_accessor :master_yaml

      def reset!
        @master_yaml = nil
      end
    end

    # ------------------------------------------------------------------
    #                        Initialisation
    # ------------------------------------------------------------------
    def initialize(config)
      super

      @i18n_path = config["i18n_load_path"] || "config/locales/en.yml"
      # Use a block form for `Hash#fetch` to satisfy performance and style linters
      @excluded_attributes = config.fetch("excluded_attributes") { %w[class id] }

      # Load master YAML once per runner invocation
      self.class.master_yaml = load_yaml(@i18n_path) unless self.class.master_yaml

      # Per-file working structures
      @haml_edits     = []   # [{ type: :plain_group, nodes:, key: } | { type: :tag, node:, key:, quote: }]
      @yaml_additions = {}   # key => value
    end

    # ------------------------------------------------------------------
    #                          Traversal
    # ------------------------------------------------------------------
    def visit_root(node)
      walk(node)
    end

    private

    def load_yaml(path)
      if File.exist?(path)
        YAML.load_file(path) || {}
      else
        { I18n.default_locale.to_s => {} }
      end
    end

    def ensure_locale_root!
      self.class.master_yaml[I18n.default_locale.to_s] ||= {}
    end

    # Depth-first walk; groups consecutive plain nodes for each parent
    def walk(parent)
      children = parent.children
      i = 0
      while i < children.size
        child = children[i]
        if child.type == :plain
          group = [ child ]
          i += 1
          while i < children.size && children[i].type == :plain
            group << children[i]
            i += 1
          end
          handle_plain_group(group)
        else
          handle_tag_literal(child) if child.type == :tag
          walk(child) if child.respond_to?(:children)
          i += 1
        end
      end
    end

    # ------------------------------------------------------------------
    #                       Detection  Helpers
    # ------------------------------------------------------------------
    def handle_plain_group(nodes)
      text = nodes.map(&:text).join(" ").strip
      return if text.empty? || NO_TRANSLATION_NEEDED.include?(text)

      key = generate_key(text)
      return unless key

      @yaml_additions[key] = text unless key_exists?(key)
      @haml_edits << { type: :plain_group, nodes: nodes, key: key }
      record_lint(nodes.first, format(MSG, text))
    end

    def handle_tag_literal(node)
      return unless node.respond_to?(:script) && node.script

      match = node.script.match(/^=\s*("([^"]*)"|'([^']*)')\s*$/)
      return unless match

      quoted  = match[1]
      content = match[2] || match[3]
      return if content.strip.empty? || NO_TRANSLATION_NEEDED.include?(content.strip)

      key = generate_key(content)
      return unless key

      @yaml_additions[key] = content unless key_exists?(key)
      @haml_edits << { type: :tag, node: node, key: key, quote: quoted }
      record_lint(node, format(MSG, content))
    end

    # ------------------------------------------------------------------
    #                       YAML handling
    # ------------------------------------------------------------------
    def apply_yaml_changes
      ensure_locale_root!
      locale_hash = self.class.master_yaml[I18n.default_locale.to_s]
      @yaml_additions.each do |k, v|
        deep_set(locale_hash, k.split("."), v)
      end
      File.write(@i18n_path, YAML.dump(self.class.master_yaml))
    end

    def key_exists?(key)
      ensure_locale_root!
      deep_key_exist?(self.class.master_yaml[I18n.default_locale.to_s], key.split("."))
    end

    # ------------------------------------------------------------------
    #                       Key helpers
    # ------------------------------------------------------------------
    def generate_key(text)
      stub = text.downcase.gsub(/[^a-z0-9\s]/, " ").squeeze(" ").strip[0, 80].tr(" ", "_")
      view_prefix = @document.file.sub(%r{^app/views/}, "").sub(/\.html\.haml$/, "").sub(/\.haml$/, "").tr("/", ".")
      base        = "#{view_prefix}.html.#{stub}"

      candidate = base
      suffix    = 1
      while key_exists?(candidate)
        candidate = "#{base}_#{suffix}"
        suffix   += 1
      end
      candidate
    end

    # ------------------------------------------------------------------
    #                       Deep Hash helpers
    # ------------------------------------------------------------------
    # Recursively checks whether the provided `path_keys` path exists in the
    # `nested_hash`. Returns true only if every key is present along the
    # traversal path.
    def deep_key_exist?(nested_hash, path_keys)
      path_keys.reduce(nested_hash) do |accumulator, key|
        return false unless accumulator.is_a?(Hash) && accumulator.key?(key)

        accumulator[key]
      end

      true
    end

    # Recursively creates nested hashes as needed and assigns `value` at the
    # deepest level indicated by `path_keys`.
    def deep_set(nested_hash, path_keys, value)
      path_keys[0..-2].reduce(nested_hash) { |accumulator, key| accumulator[key] ||= {} }
      nested_hash.dig(*path_keys[0..-2])[path_keys.last] = value
    end
  end
end

# Reset linter state at load so each `haml-lint` run starts fresh
HamlLint::HardcodedStringLinter.reset!
