# frozen_string_literal: true

class ExperienceComponent
  class ActionsComponent < ViewComponent::Base
    attr_reader :experience

    def initialize(experience:)
      super
      @experience = experience
    end
  end
end
