# frozen_string_literal: true
# shareable_constant_value: literal

ActiveRecordDoctor.configure do |config|
  config.detector :unindexed_deleted_at, enabled: false
end
