# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Registry for managing and discovering indexers
class IndexerRegistry
  class << self
    # Get all available indexer classes
    def all_indexers
      @all_indexers ||= discover_indexers
    end

    # Get enabled indexer classes based on configuration
    def enabled_indexers
      all_indexers.select { |indexer_class| indexer_enabled?(indexer_class) }
    end

    # Get indexer class by platform name
    def find_indexer(platform_name)
      all_indexers.find { |indexer_class| indexer_class.new.platform_name == platform_name.to_s }
    end

    # Check if an indexer is enabled
    def indexer_enabled?(indexer_class)
      config = indexer_config(indexer_class)
      config.fetch("enabled") { false }
    end

    # Get configuration for an indexer
    def indexer_config(indexer_class)
      platform_name = indexer_class.new.platform_name
      Rails.application.config_for(:indexers)[platform_name] || {}
    rescue StandardError
      {}
    end

    # Get all platform names
    def platform_names
      all_indexers.map { |indexer_class| indexer_class.new.platform_name }
    end

    private

    def discover_indexers
      # Load all indexer files
      Dir[Rails.root.join("app/indexers/**/*_indexer.rb")].each do |file|
        require_dependency file
      end

      # Find all classes that inherit from BaseIndexer
      ObjectSpace.each_object(Class).select do |klass|
        klass < BaseIndexer && klass != BaseIndexer
      end
    end
  end
end
