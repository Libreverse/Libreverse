# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# InlineSvg + Propshaft compatibility / defensive patch
#
# We are seeing the following error coming from the middleware (EmojiReplacer):
#   undefined method `load_path' for an instance of Sprockets::Environment
#   inline_svg/propshaft_asset_finder.rb:12:in `pathname'
#
# The inline_svg gem (1.10.0) tries to detect Propshaft and assumes a Propshaft
# environment that responds to `load_path`. In our application `Rails.application.assets`
# is a Sprockets::Environment (or possibly nil in production) which does not expose the
# interface expected by the gem, causing NoMethodError and breaking emoji processing.
#
# We patch the PropshaftAssetFinder to gracefully fall back to a simple filesystem
# search in common SVG locations when the expected interface is missing. This keeps
# dependent gems (e.g. thredded) functional without pulling in the full sprockets
# integration or changing their code.
#
# Safe to remove once inline_svg releases a version that guards its calls or once we
# migrate fully to a supported finder API.

if defined?(InlineSvg::PropshaftAssetFinder)
  InlineSvg::PropshaftAssetFinder.class_eval do
    # Keep a reference to the original implementation (only once) so we can call it when safe.
    alias_method :__original_pathname, :pathname unless method_defined?(:__original_pathname)

    # Accept variable args to be resilient if the gem changes invocation style.
    def pathname(*args)
      # If called with no arguments (as per error trace), we can't do anything meaningful.
      return nil if args.empty?

      filename = args.first
      env = ::Rails.application.assets

      begin
        if env.respond_to?(:load_path)
          # Delegate with original arity/args only if environment supports expected API.
          return args.length == 1 ? __original_pathname(filename) : __original_pathname(*args)
        end
      rescue ArgumentError
        # Fall through to fallback search.
      end

      # Fallback: search a curated list of asset directories.
      candidate_dirs = [
        ::Rails.root.join("app/assets/images"),
        ::Rails.root.join("app/icons"),
        ::Rails.root.join("app/emoji"),
        ::Rails.root.join("public/images")
      ].select { |p| Dir.exist?(p) }

      candidate_dirs.each do |base|
        full = base.join(filename)
        return full if full.exist?
      end

      nil
    end
  end
end
