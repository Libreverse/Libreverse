# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class ExperienceComponent < ViewComponent::Base
  attr_reader :experience

  def initialize(experience:)
    super
    @experience = experience
  end
end
