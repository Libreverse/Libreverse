module Federails::Moderation
  # rubocop:disable Style/ClassVars

  # Stores the Federails::Moderation configuration in a _singleton_.
  module Configuration
    # A proc that is called any time new report is created
    # Useful for sending notifications
    mattr_accessor :after_report_created
  end
  # rubocop:enable Style/ClassVars
end
