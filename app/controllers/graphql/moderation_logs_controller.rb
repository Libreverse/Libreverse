# frozen_string_literal: true
# shareable_constant_value: literal

module Graphql
  class ModerationLogsController < GraphqlApplicationController
    model("ModerationLog")

    # Queries
    action(:index).permit(limit: "Int").returns("[ModerationLog!]!")

    def index
      require_authentication

      # Admin sees all logs, users see only their own
      logs = if current_account.admin?
        ModerationLog.recent
      else
        ModerationLog.where(account_id: current_account.id).recent
      end

      limit = [ params[:limit] || 20, 100 ].min
      logs.limit(limit)
    end
  end
end
