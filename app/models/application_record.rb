# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

class ApplicationRecord < ActiveRecord::Base
  include CableReady::Updatable
  include CableReady::Broadcaster

  primary_abstract_class
end
