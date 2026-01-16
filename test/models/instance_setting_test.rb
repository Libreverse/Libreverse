# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: instance_settings
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  key         :string(255)      not null
#  value       :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_instance_settings_on_key  (key) UNIQUE
#
require "test_helper"

class InstanceSettingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
