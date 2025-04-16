# frozen_string_literal: true

module ExperienceComponent
  class ActionsComponent < ViewComponent::Base
    attr_reader :experience

    def initialize(experience:)
      super
      @experience = experience
    end
  end
end
