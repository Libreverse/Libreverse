# frozen_string_literal: true

module Admin
  class IndexersController < ApplicationController
  before_action :ensure_admin_access

  def index
    @indexers = available_indexers
    @indexing_runs = IndexingRun.recent.limit(10).includes(:run)
  end

  def show
    @platform_name = params[:id]
    @indexer_class = find_indexer_class(@platform_name)

    if @indexer_class
      @indexer = @indexer_class.new
      @recent_runs = IndexingRun.for_indexer(@indexer_class.name).recent.limit(20)
      @config = @indexer.config
    else
      redirect_to admin_indexers_path, alert: "Indexer not found: #{@platform_name}"
    end
  end

  def run
    platform_name = params[:id]
    indexer_class = find_indexer_class(platform_name)

    if indexer_class
      IndexerJob.perform_later(indexer_class.name, {})
      redirect_to admin_indexer_path(platform_name), notice: "Indexer job queued for #{platform_name}"
    else
      redirect_to admin_indexers_path, alert: "Indexer not found: #{platform_name}"
    end
  end

    private

  def ensure_admin_access
    # Add your admin authentication logic here
    # For now, we'll allow access - you can integrate with your existing auth system
    true
  end

  def available_indexers
    # Manually discover indexers since IndexerRegistry has autoload issues
    indexers = {}

    # Load configuration
    config = load_indexer_config
    return indexers unless config

    base_indexers = config["indexers"] || {}
    env_overrides = config[Rails.env] || {}
    env_indexers = env_overrides["indexers"] || {}

    base_indexers.each do |platform_name, base_config|
      env_config = env_indexers[platform_name] || {}
      merged_config = base_config.deep_merge(env_config)

      indexer_class = find_indexer_class(platform_name)

      indexers[platform_name] = {
        platform_name: platform_name,
        enabled: merged_config["enabled"],
        config: merged_config,
        indexer_class: indexer_class,
        exists: !indexer_class.nil?
      }
    end

    indexers
  end

  def find_indexer_class(platform_name)
    class_name = "Metaverse::#{platform_name.camelize}Indexer"
    class_name.constantize
  rescue NameError
    nil
  end

  def load_indexer_config
    config_path = Rails.root.join("config/indexers.yml")
    return nil unless File.exist?(config_path)

    YAML.load_file(config_path)
  rescue StandardError => e
    Rails.logger.error "Failed to load indexer config: #{e.message}"
    nil
  end
  end
end
