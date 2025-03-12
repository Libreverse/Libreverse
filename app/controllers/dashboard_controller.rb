class DashboardController < ApplicationController
  def index
    @account = current_account
    @account_created_at = @account.created_at.strftime("%B %d, %Y")
    @last_login_at = session[:last_login_at] ? Time.at(session[:last_login_at]).strftime("%B %d, %Y at %H:%M") : "Unknown"
    
    # If password was created more than 90 days ago, show warning
    @password_age = (Time.now - @account.password_changed_at).to_i / 86400 rescue nil
    @password_warning = @password_age && @password_age > 90
    
    # Get password strength based on length
    @password_strength = calculate_password_strength
  end
  
  private
  
  def calculate_password_strength
    password_length = session[:password_length] || 0
    
    case password_length
    when 0..11
      { level: "weak", class: "text-danger", message: "Your password is too short. Consider changing it." }
    when 12..15
      { level: "medium", class: "text-warning", message: "Your password meets minimum requirements." }
    when 16..19
      { level: "strong", class: "text-success", message: "Your password is strong." }
    else
      { level: "very strong", class: "text-success fw-bold", message: "Your password is very strong." }
    end
  end
end
