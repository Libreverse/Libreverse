# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: indexed_content_vectors
#
#  id                 :bigint           not null, primary key
#  content_hash       :text(65535)      not null
#  generated_at       :datetime         not null
#  vector_data        :text(65535)
#  vector_hash        :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  indexed_content_id :bigint           not null
#
# Indexes
#
#  idx_icv_on_vh_and_icid                               (vector_hash,indexed_content_id) UNIQUE
#  index_indexed_content_vectors_on_generated_at        (generated_at)
#  index_indexed_content_vectors_on_indexed_content_id  (indexed_content_id) UNIQUE
#  index_indexed_content_vectors_on_vector_hash         (vector_hash)
#
# Foreign Keys
#
#  fk_rails_...  (indexed_content_id => indexed_contents.id)
#
require "test_helper"

class IndexedContentVectorTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
