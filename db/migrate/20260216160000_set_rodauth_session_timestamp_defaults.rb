# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

class SetRodauthSessionTimestampDefaults < ActiveRecord::Migration[8.1]
   extend T::Sig
  sig { returns(NilClass) }
  def up
    # TiDB in this environment rejects default datetime expressions on ALTER TABLE.
    # Timestamp values are populated at write time from Rodauth hooks.
  end

  sig { returns(NilClass) }
  def down
    # no-op
  end
end
