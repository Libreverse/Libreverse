class Experience < ApplicationRecord
  belongs_to :account, optional: true
  
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 2000 }
  validates :author, length: { maximum: 255 }
  validates :content, length: { maximum: 50000 }
  
  # Ensure content is sanitized before saving
  before_save :sanitize_content
  
  private
  
  def sanitize_content
    return unless content_changed?
    
    # Rails' sanitize helper
    self.content = ActionController::Base.helpers.sanitize(
      content,
      tags: %w[p br h1 h2 h3 h4 h5 h6 ul ol li strong em b i u code pre blockquote],
      attributes: %w[class id]
    )
  end
end
