# frozen_string_literal: true

class AccountReflex < ApplicationReflex
  def destroy
    # Run the close_account internal request via Rodauth
    RodauthMain.close_account(account_id: current_account.id)

    # Clear session
    session.clear

    # Redirect to root
    cable_ready.redirect_to(url: root_path)
  end
end
