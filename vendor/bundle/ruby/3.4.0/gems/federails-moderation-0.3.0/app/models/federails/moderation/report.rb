class Federails::Moderation::Report < ApplicationRecord
  belongs_to :federails_actor, class_name: "Federails::Actor", optional: true
  belongs_to :object, polymorphic: true, optional: true

  after_create :execute_create_callback

  def resolve!
    update!(resolved_at: DateTime.now, resolution: "resolved")
  end

  def ignore!
    update!(resolved_at: DateTime.now, resolution: "ignored")
  end

  def reporter_address
    if federails_actor
      federails_actor.at_address
    else
      URI.parse(federated_url).host
    end
  end

  def local?
    federails_actor&.local?
  end

  private

  def execute_create_callback
    Federails::Moderation::Configuration.after_report_created&.call self
  end
end
