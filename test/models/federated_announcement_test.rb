# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: federated_announcements
#
#  id              :bigint           not null, primary key
#  activitypub_uri :string(255)      not null
#  announced_at    :datetime         not null
#  experience_url  :string(255)
#  source_domain   :string(255)      not null
#  title           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_federated_announcements_on_activitypub_uri  (activitypub_uri) UNIQUE
#  index_federated_announcements_on_announced_at     (announced_at)
#  index_federated_announcements_on_source_domain    (source_domain)
#
require "test_helper"

class FederatedAnnouncementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
