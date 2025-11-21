# frozen_string_literal: true
# shareable_constant_value: literal

class IndexedContentVector < ApplicationRecord
  belongs_to :indexed_content

  validates :vector_data, presence: true
  validates :vector_hash, presence: true, uniqueness: { scope: :indexed_content_id }
  validates :generated_at, presence: true
  validates :content_hash, presence: true

  # JSON serialization for vector data
  serialize :vector_data, type: Array, coder: JSON

  # Calculate cosine similarity between this vector and another
  def cosine_similarity(other_vector)
    return 0.0 if other_vector.blank?

    vector_a = vector_data.is_a?(Array) ? vector_data : JSON.parse(vector_data)
    vector_b = other_vector.is_a?(Array) ? other_vector : JSON.parse(other_vector)

    VectorSimilarityService.cosine_similarity(vector_a, vector_b)
  end

  # Generate a hash of the source content for change detection
  def self.generate_content_hash(title, description, author)
    # Ensure we have at least some content to hash
    content_parts = [ title, description, author ].compact.map(&:to_s).reject(&:empty?)
    content = content_parts.any? ? content_parts.join("|") : "empty_content"
    Digest::MD5.hexdigest(content)
  end

  # Check if the vector needs regeneration
  def needs_regeneration?(indexed_content)
    current_hash = self.class.generate_content_hash(
      indexed_content.title,
      indexed_content.description,
      indexed_content.author
    )
    content_hash != current_hash
  end
end
