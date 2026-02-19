# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Service for adding example experiences to Libreverse
# Based on the rails runner script for creating sample experiences
class ExampleExperiencesService
  class << self
    def add_examples
      Rails.logger.debug "🎯 Adding example experiences to Libreverse..."

      # First, let's find or create an admin account to own these experiences
      admin_account = find_or_create_admin_account

      created_count = 0
      failed_count = 0

      index = 0
      while index < sample_html_files.length
        html_file_data = sample_html_files[index]
        exp_data = experiences_data[index]
        Rails.logger.debug "\n📝 Creating: '#{exp_data[:title]}'..."

        begin
          # Skip if experience already exists
          if Experience.exists?(title: exp_data[:title], author: exp_data[:author])
            Rails.logger.debug "   ⚠️  Experience '#{exp_data[:title]}' already exists, skipping..."
            next
          end

          experience = create_experience_with_file(exp_data, html_file_data, admin_account)

          if experience.persisted?
            Rails.logger.debug "   ✅ Successfully created '#{experience.title}' (ID: #{experience.id})"
            created_count += 1
          else
            Rails.logger.debug "   ❌ Failed to create '#{exp_data[:title]}': #{experience.errors.full_messages.join(', ')}"
            failed_count += 1
          end

          # Small delay between creations
          sleep(0.1)
        rescue StandardError => e
          Rails.logger.debug "   ❌ Error creating '#{exp_data[:title]}': #{e.message}"
          failed_count += 1
        end

        index += 1
      end

      print_summary(created_count, failed_count)

      { created: created_count, failed: failed_count }
    end

    def delete_examples
      example_titles = experiences_data.map { |exp| exp[:title] }
      deleted_count = Experience.where(title: example_titles).destroy_all.count
      { deleted: deleted_count }
    end

    def experience_data
      [
        {
          title: "Virtual Art Gallery Experience",
          description: "Step into a beautiful virtual art gallery featuring digital artworks and interactive displays. Explore different artistic styles and immerse yourself in a curated collection of digital masterpieces.",
          author: "Gallery Curator",
          html_file_data: {
            filename: "virtual_gallery.html",
            content: virtual_gallery_html
          }
        },
        {
          title: "Interactive Fantasy Adventure",
          description: "Embark on a choose-your-own-adventure story set in a mysterious enchanted forest. Make decisions that shape your journey and discover the secrets hidden within the mystical woodland.",
          author: "Story Weaver",
          html_file_data: {
            filename: "fantasy_adventure.html",
            content: fantasy_adventure_html
          }
        },
        {
          title: "Space Mission Control Dashboard",
          description: "Experience life as a space mission controller with this interactive dashboard. Monitor multiple planets, track space missions, and stay connected with deep space communications.",
          author: "Astronaut Alpha",
          html_file_data: {
            filename: "space_dashboard.html",
            content: space_dashboard_html
          }
        },
        {
          title: "Dynamic Audio Visualizer",
          description: "A mesmerizing audio visualization experience with multiple modes and interactive controls. Watch as sound comes to life through beautiful animated graphics and responsive visual effects.",
          author: "Sound Engineer",
          html_file_data: {
            filename: "music_visualizer.html",
            content: music_visualizer_html
          }
        },
        {
          title: "Interactive Digital Garden",
          description: "Create and tend your own digital garden! Plant flowers, add clouds, make it rain, and watch your virtual garden grow. A peaceful and interactive nature experience.",
          author: "Digital Gardener",
          html_file_data: {
            filename: "digital_garden.html",
            content: digital_garden_html
          }
        },
        {
          title: "Retro Arcade Experience",
          description: "A nostalgic journey back to the golden age of arcade games. Features classic game aesthetics, pixel art styling, and interactive elements that capture the spirit of retro gaming.",
          author: "Pixel Artist",
          html_file_data: {
            filename: "retro_arcade.html",
            content: retro_arcade_html
          }
        }
      ]
    end

    private

    def find_or_create_admin_account
      admin_account = Account.find_by(admin: true)

      if admin_account.nil?
        Rails.logger.debug "⚠️  No admin account found. Creating one..."

        # Create an admin account (bypassing validations for username)
        admin_account = Account.new(
          username: "admin_demo",
          status: 2, # verified
          admin: true,
          guest: false
        )

        # Save without validations to avoid moderation issues with demo data
        admin_account.save!(validate: false)
        Rails.logger.debug "✅ Created admin account: #{admin_account.username} (ID: #{admin_account.id})"
      else
        Rails.logger.debug "✅ Using existing admin account: #{admin_account.username} (ID: #{admin_account.id})"
      end

      admin_account
    end

    def create_experience_with_file(exp_data, html_file_data, admin_account)
      # Create the experience
      experience = Experience.new(
        title: exp_data[:title],
        description: exp_data[:description],
        author: exp_data[:author],
        account: admin_account,
        approved: true, # Auto-approve since it's created by admin
        offline_available: exp_data.fetch(:offline_available) { true } # Default to true for examples
      )

      # Create and attach the HTML file
      html_content = html_file_data[:content]
      filename = html_file_data[:filename]

      # Create a StringIO object to avoid writing decrypted data to disk
      html_io = StringIO.new(html_content)

      # Attach the file
      experience.html_file.attach(
        io: html_io,
        filename: filename,
        content_type: "text/html"
      )

      # Save the experience (skip validations to bypass moderation for demo data)
      experience.save!(validate: false)

      temp_file.close
      temp_file.unlink

      experience
    end

    def print_summary(created_count, failed_count)
      Rails.logger.debug "\n#{'=' * 60}"
      Rails.logger.debug "🎯 Experience Creation Summary:"
      Rails.logger.debug "   ✅ Successfully created: #{created_count} experiences"
      Rails.logger.debug "   ❌ Failed to create: #{failed_count} experiences"
      Rails.logger.debug "   📊 Total experiences in database: #{Experience.count}"
      Rails.logger.debug "   🎉 Approved experiences: #{Experience.approved.count}"
      Rails.logger.debug "   ⏳ Pending approval: #{Experience.pending_approval.count}"

      if created_count.positive?
        Rails.logger.debug "\n🚀 Great! You now have example experiences to explore."
        Rails.logger.debug "   💡 Visit the experiences page to see them in action!"
        Rails.logger.debug "   🔗 Or use the API to interact with them programmatically."
      end

      Rails.logger.debug "\n🎉 Done! Your Libreverse instance now has sample content to explore."
    end

    def sample_html_files
      [
        {
          filename: "virtual_gallery.html",
          content: virtual_gallery_html
        },
        {
          filename: "interactive_story.html",
          content: interactive_story_html
        },
        {
          filename: "space_exploration.html",
          content: space_exploration_html
        },
        {
          filename: "music_visualizer.html",
          content: music_visualizer_html
        },
        {
          filename: "digital_garden.html",
          content: digital_garden_html
        },
        {
          filename: "retro_arcade.html",
          content: retro_arcade_html
        },
        {
          filename: "meditation_space.html",
          content: meditation_space_html
        }
      ]
    end

    def experiences_data
      [
        {
          title: "Virtual Art Gallery Experience",
          description: "Step into a beautiful virtual art gallery featuring digital artworks and interactive displays. Explore different artistic styles and immerse yourself in a curated collection of digital masterpieces.",
          author: "Gallery Curator",
          offline_available: true
        },
        {
          title: "Interactive Fantasy Adventure",
          description: "Embark on a choose-your-own-adventure story set in a mysterious enchanted forest. Make decisions that shape your journey and discover the secrets hidden within the mystical woodland.",
          author: "Story Weaver",
          offline_available: true
        },
        {
          title: "Space Mission Control Dashboard",
          description: "Experience life as a space mission controller with this interactive dashboard. Monitor multiple planets, track space missions, and stay connected with deep space communications.",
          author: "Astronaut Alpha",
          offline_available: true
        },
        {
          title: "Dynamic Audio Visualizer",
          description: "A mesmerizing audio visualization experience with multiple modes and interactive controls. Watch as sound comes to life through beautiful animated graphics and responsive visual effects.",
          author: "Sound Engineer",
          offline_available: true
        },
        {
          title: "Interactive Digital Garden",
          description: "Create and tend your own digital garden! Plant flowers, add clouds, make it rain, and watch your virtual garden grow. A peaceful and interactive nature experience.",
          author: "Digital Gardener",
          offline_available: true
        },
        {
          title: "Retro Arcade Experience",
          description: "A nostalgic journey back to the golden age of arcade games. Features classic game aesthetics, pixel art styling, and interactive elements that capture the spirit of retro gaming.",
          author: "Pixel Artist",
          offline_available: true
        },
        {
          title: "Meditation and Mindfulness Space",
          description: "A tranquil digital environment designed for meditation and relaxation. Features ambient sounds, breathing exercises, and calming visual elements to help you find inner peace.",
          author: "Zen Master",
          offline_available: true
        }
      ]
    end

    def virtual_gallery_html
      render_example_document("virtual_gallery")
    end

    def interactive_story_html
      render_example_document("interactive_story")
    end

    def space_exploration_html
      render_example_document("space_exploration")
    end

    def music_visualizer_html
      render_example_document("music_visualizer")
    end

    def digital_garden_html
      render_example_document("digital_garden")
    end

    def retro_arcade_html
      render_example_document("retro_arcade")
    end

    def meditation_space_html
      render_example_document("meditation_space")
    end

    def render_example_document(name)
      StaticHtmlDocumentComponent.new(
        html: File.read(Rails.root.join("app/static/example_experiences/#{name}.html"))
      ).call
    end
  end
end
