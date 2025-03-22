class ExperienceComponent < ViewComponent::Base
  attr_reader :experience

  def initialize(experience:)
    @experience = experience
  end
end
