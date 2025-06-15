# frozen_string_literal: true

class SetExampleExperiencesToNotFederate < ActiveRecord::Migration[8.0]
  def up
    # Update existing example experiences to not federate
    example_titles = [
      "Virtual Art Gallery Experience",
      "Interactive Fantasy Adventure",
      "Space Mission Control Dashboard",
      "Dynamic Audio Visualizer",
      "Interactive Digital Garden",
      "Retro Arcade Experience"
    ]

    Experience.where(title: example_titles).update_all(federate: false)
  end

  def down
    # If rolling back, set example experiences back to federating
    example_titles = [
      "Virtual Art Gallery Experience",
      "Interactive Fantasy Adventure",
      "Space Mission Control Dashboard",
      "Dynamic Audio Visualizer",
      "Interactive Digital Garden",
      "Retro Arcade Experience"
    ]

    Experience.where(title: example_titles).update_all(federate: true)
  end
end
