module Federails::Moderation
  class ReportCreationService < ApplicationService
    def initialize(activity)
      @activity = activity
      Rails.logger.info "Report recieved: #{@activity.inspect}"
    end

    def call
      Report.create!(
        federails_actor: find_reporter,
        object: find_objects.first,
        federated_url: @activity["id"],
        content: @activity["content"]
      )
    end

    private

    def find_reporter
      Federails::Actor.find_or_create_by_federation_url(@activity["actor"])
    rescue ActiveRecord::RecordInvalid, URI::InvalidURIError
      # Anonymous reports will try to create invalid actors, so we end up here
      nil
    end

    def find_objects
      objects = Array(@activity["object"]).map { |url|
        begin
          # Find reported actors
          Federails::Actor.find_by_federation_url(url)
          # Other objects could be here too, but they will come later
        rescue ActiveRecord::RecordNotFound
          nil
        end
      }.compact
      Rails.logger.warn "Federails::Moderation cannot currently handle multiple objects in a single report, only the first has been logged" if objects.length > 1
      objects
    end
  end
end
