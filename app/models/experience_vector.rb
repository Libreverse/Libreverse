# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: experience_vectors
#
#  id            :bigint           not null, primary key
#  generated_at  :datetime         not null
#  vector_data   :text(65535)      not null
#  vector_hash   :string(255)      not null
#  version       :integer          default(1), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  experience_id :bigint           not null
#
# Indexes
#
#  index_experience_vectors_on_experience_id  (experience_id) UNIQUE
#  index_experience_vectors_on_generated_at   (generated_at)
#
# Foreign Keys
#
#  fk_rails_...  (experience_id => experiences.id)
#
class ExperienceVector < ApplicationRecord
  # Enable SecondLevelCache for automatic read-through/write-through caching
  second_level_cache expires_in: 30.minutes

  belongs_to :experience

  validates :vector_data, presence: true
  validates :vector_hash, presence: true
  validates :generated_at, presence: true
  validates :version, presence: true, numericality: { greater_than: 0 }
  validates :vector_hash, length: { maximum: 255 }
  validates :vector_data, length: { maximum: 65_535 }, allow_blank: true
  validate :vector_hash_unique_for_experience

  # JSON serialization for vector data
  serialize :vector_data, type: Array, coder: JSON

  # Calculate cosine similarity between this vector and another
  def cosine_similarity(other_vector)
    return 0.0 if other_vector.blank?

    vector_a = vector_data.is_a?(Array) ? vector_data : JSON.parse(vector_data)
    # Fix: remove redundant conditional branches
    vector_b = other_vector.is_a?(Array) ? other_vector : JSON.parse(other_vector)

    VectorSimilarityService.cosine_similarity(vector_a, vector_b)
  end

  # Generate a hash of the source content for change detection
  def self.generate_content_hash(title, description, author)
    content = [ title, description, author ].compact.join("|")
    Digest::MD5.hexdigest(content)
  end

  # Check if the vector needs regeneration
  def needs_regeneration?(experience)
    current_hash = self.class.generate_content_hash(
      experience.title,
      experience.description,
      experience.author
    )
    vector_hash != current_hash
  end

  private

  def vector_hash_unique_for_experience
    return if experience_id.blank? || vector_hash.blank?

    conflict = self.class.where(experience_id: experience_id, vector_hash: vector_hash).where.not(id: id).exists?
    errors.add(:vector_hash, :taken) if conflict
  end
end
