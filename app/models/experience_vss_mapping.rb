# frozen_string_literal: true

# Model for mapping between experiences and VSS virtual table entries
class ExperienceVssMapping < ApplicationRecord
  belongs_to :experience

  validates :experience_id, presence: true, uniqueness: true
  validates :vss_rowid, presence: true, uniqueness: true

  # Find the VSS rowid for a given experience
  def self.vss_rowid_for_experience(experience_id)
    find_by(experience_id: experience_id)&.vss_rowid
  end

  # Find the experience ID for a given VSS rowid
  def self.experience_id_for_vss_rowid(vss_rowid)
    find_by(vss_rowid: vss_rowid)&.experience_id
  end
end
