# frozen_string_literal: true

class WellKnownController < ApplicationController
  skip_before_action :_enforce_privacy_consent
  skip_forgery_protection

  # Serve /.well-known/security.txt
  def security_txt
    content = <<~TXT
      Contact: https://signal.me/#eu/Ui1-KTmlgnCbNj491iq3HSOJtrkY1aVHm4n0v97dvkGDbCqWsExOu66Fzg7-7iC9
      Contact: mailto:resists-oysters.0s@icloud.com
      Contact: https://x.com/georgebaskervil
      Policy: https://libreverse.dev/privacy
      Preferred-Languages: en
      Acknowledgements: https://libreverse.dev/security
      Expires: #{1.year.from_now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')}
    TXT
    render plain: content, content_type: 'text/plain'
  end

  # Serve /.well-known/privacy.txt
  def privacy_txt
    content = <<~TXT
      This service is operated by Libreverse. See our privacy policy at:
      https://libreverse.dev/privacy
    TXT
    render plain: content, content_type: 'text/plain'
  end
end 