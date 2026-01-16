# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: indexing_runs
#
#  id              :bigint           not null, primary key
#  completed_at    :datetime
#  configuration   :text(65535)
#  error_details   :text(65535)
#  error_message   :text(65535)
#  indexer_class   :string(255)      not null
#  items_failed    :integer          default(0)
#  items_processed :integer          default(0)
#  started_at      :datetime
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_indexing_runs_on_indexer_class  (indexer_class)
#  index_indexing_runs_on_started_at     (started_at)
#  index_indexing_runs_on_status         (status)
#
require "test_helper"

class IndexingRunTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
