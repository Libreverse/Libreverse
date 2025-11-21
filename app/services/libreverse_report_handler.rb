# frozen_string_literal: true
# shareable_constant_value: literal

# Service to handle incoming ActivityPub reports about federated content
class LibreverseReportHandler
  def initialize(report)
    @report = report
  end

  def process
    # Find the reported experience
    experience = find_reported_experience
    return unless experience

    # Create moderation log entry
    ModerationLog.create!(
      field: "federated_content",
      model_type: "Experience",
      content: experience.title,
      reason: "Reported via ActivityPub: #{@report.content}",
      account: experience.account,
      violations_data: {
        report_id: @report.id,
        reporter_actor: @report.actor&.federated_url,
        federation_source: true,
        reported_uri: @report.object_uri
      }.to_json
    )

    # Notify admins about federated report
    notify_admins_of_federated_report(experience, @report)

    Rails.logger.info "Processed federated report for experience #{experience.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to process federated report: #{e.message}"
  end

  private

  def find_reported_experience
    # Parse the reported object URI to find local experience
    # URI pattern: https://domain.com/federation/actors/ACTOR_ID/notes/EXPERIENCE_ID

    return nil unless @report.object_uri

    # Try to extract experience ID from the URI
    match = @report.object_uri.match(%r{/notes/(\d+)})
    return nil unless match

    experience_id = match[1]
    Experience.find_by(id: experience_id)
  end

  def notify_admins_of_federated_report(experience, _report)
    # Send notifications to admins about the federated report
    admin_accounts = Account.where(admin: true)

    admin_accounts.each do |admin|
      # This could be expanded to send email notifications or create in-app notifications
      Rails.logger.info "Notifying admin #{admin.username} about federated report for experience #{experience.id}"
    end
  end
end
