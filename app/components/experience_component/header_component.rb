module ExperienceComponent
  class HeaderComponent < ViewComponent::Base
  attr_reader :experience

  def initialize(experience:)
    @experience = experience
  end
  end
end
