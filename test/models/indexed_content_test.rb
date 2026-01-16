# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: indexed_contents
#
#  id              :bigint           not null, primary key
#  author          :string(255)
#  content_type    :string(255)      not null
#  coordinates     :text(65535)
#  description     :text(65535)
#  last_indexed_at :datetime
#  metadata        :text(4294967295)
#  source_platform :string(255)      not null
#  title           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  external_id     :string(255)      not null
#
# Indexes
#
#  index_indexed_contents_on_content_type                     (content_type)
#  index_indexed_contents_on_last_indexed_at                  (last_indexed_at)
#  index_indexed_contents_on_source_platform                  (source_platform)
#  index_indexed_contents_on_source_platform_and_external_id  (source_platform,external_id) UNIQUE
#
require "test_helper"

class IndexedContentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
