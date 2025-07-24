# frozen_string_literal: true

# Background job to import indexed metaverse content as experiences
class ImportMetaverseExperiencesJob < ApplicationJob
  queue_as :default

  # Import all indexed content from a specific platform
  def perform(platform = nil, force_reimport: false)
    scope = IndexedContent.all
    scope = scope.where(source_platform: platform) if platform.present?

    unless force_reimport
      # Only import content that hasn't been imported yet
      existing_experience_content_ids = Experience
                                        .indexed_metaverse
                                        .joins(:indexed_content)
                                        .pluck(:indexed_content_id)

      scope = scope.where.not(id: existing_experience_content_ids)
    end

    Rails.logger.info "Starting metaverse experience import: #{scope.count} items to process"

    results = MetaverseExperienceImportService.bulk_import(scope)

    Rails.logger.info "Metaverse experience import completed: #{results[:created]} created, #{results[:updated]} updated, #{results[:errors].size} errors"

    # Log any errors
    results[:errors].each do |error|
      Rails.logger.error "Failed to import indexed_content #{error[:indexed_content_id]}: #{error[:error]}"
    end

    results
  end
end
