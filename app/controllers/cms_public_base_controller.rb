class CmsPublicBaseController < ApplicationController
  layout "application"

  # Ensure meta tags etc. can be set; keep any before_actions from ApplicationController
  # You can customize per-need (e.g., disable auth filters for CMS):
  skip_before_action :verify_authenticity_token, only: []
end
