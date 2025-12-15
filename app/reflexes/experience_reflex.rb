# frozen_string_literal: true
# shareable_constant_value: literal

class ExperienceReflex < ApplicationReflex
  def approve
    authorize_admin!
    experience = Experience.find(element.dataset[:id])
    experience.update(approved: true)
    # Assuming there is a row or card to update.
    # If it's the show page, we might redirect or show a success message.
    # If it's the index page, we update the row.
    morph :nothing
    cable_ready.console_log(message: "Experience approved")
    # We can also broadcast a toast
  end

  def add_examples
    authorize_admin!
    result = ExampleExperiencesService.add_examples
    cable_ready.console_log(message: "Added #{result[:created]} examples")
    morph :nothing
  end

  def restore_examples
    authorize_admin!
    result = ExampleExperiencesService.restore_examples
    cable_ready.console_log(message: "Restored #{result[:restored]} examples")
    morph :nothing
  end

  def delete_examples
    authorize_admin!
    result = ExampleExperiencesService.delete_examples
    cable_ready.console_log(message: "Deleted #{result[:deleted]} examples")
    morph :nothing
  end

  private

  def authorize_admin!
    raise "Unauthorized" unless current_account&.admin?
  end
end
