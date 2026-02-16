# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class MigrateExperienceBooleansToFlags < ActiveRecord::Migration[8.1]
  def up
    # Migrate existing boolean data to flags bit field
    # Bit positions: 1=approved, 2=federate, 4=federated_blocked, 8=offline_available

    # rubocop:disable Rails/SkipsModelValidations
    Experience.find_each do |experience|
      flags = 0
      flags |= 1 if experience.approved?
      flags |= 2 if experience.federate?
      flags |= 4 if experience.federated_blocked?
      flags |= 8 if experience.offline_available?

      experience.update_columns(flags: flags)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    # Revert by setting all flags to 0
    Experience.update_all(flags: 0) # rubocop:disable Rails/SkipsModelValidations
  end
end
