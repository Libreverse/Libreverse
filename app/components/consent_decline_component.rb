# typed: true
# frozen_string_literal: true

class ConsentDeclineComponent < Phlex::HTML
  def view_template
    div(class: "consent-decline") do
      h1 { "Consent Required" }
      p do
        plain "You declined the Privacy & Cookie Policy. Libreverse cannot operate without the strictly necessary cookies described in the policy. Please reconsider to continue."
      end
      button(class: "btn-secondary", data: { action: "click->consent#showScreen" }) { "Go Back" }
    end
  end
end
