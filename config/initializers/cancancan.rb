# frozen_string_literal: true
# shareable_constant_value: literal

# CanCanCan configuration

# Handle authorization failures
module ActionController
  class Base
  rescue_from CanCan::AccessDenied do |_exception|
    respond_to do |format|
      format.json { head :forbidden, content_type: "text/html" }
      format.html do
        if user_signed_in?
          flash[:alert] = if guest_user?
            "This feature is not available for guest accounts. Please create a full account to access this."
          else
            "You are not authorized to access this page."
          end
redirect_to(request.referer || root_path)
        else
          flash[:alert] = "You must be logged in to access this page."
          redirect_to "/login"
        end
      end
      format.js { head :forbidden, content_type: "text/html" }
    end
  end
  end
end
