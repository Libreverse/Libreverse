# frozen_string_literal: true
# shareable_constant_value: literal

namespace :vector_search do
  # Helper method to check if operations should be forced without prompting
  def force_operation?
    ARGV.include?("--force")
  end

  # Helper method to get user confirmation or proceed if forced
  def confirm_operation(message, success_message = nil, cancel_message = nil)
    if force_operation?
      puts success_message || "✅ Proceeding (forced)"
      return true
    end

    print "⚠️  #{message} Continue? (y/N): "
    confirmation = $stdin.gets.chomp.downcase

    if %w[y yes].include?(confirmation)
      puts success_message || "✅ Proceeding"
      true
    else
      puts cancel_message || "❌ Operation cancelled"
      false
    end
  end

  desc "Initialize vector search system by vectorizing all experiences"
  task initialize: :environment do
    puts "🚀 Initializing vector search system..."

    total_experiences = Experience.count
    puts "📊 Found #{total_experiences} experiences to vectorize"

    if total_experiences.zero?
      puts "⚠️  No experiences found. Vector search system will be ready when experiences are created."
      next
    end

    # Queue batch vectorization job for ALL experiences
    BatchVectorizeExperiencesJob.perform_later(
      batch_size: 50,
      force_regeneration: false,
      approved_only: false
    )

    puts "✅ Batch vectorization job queued. Check logs for progress."
    puts "💡 You can monitor progress with: rails vector_search:status"
  end

  desc "Check the status of vector search system"
  task status: :environment do
    puts "📈 Vector Search System Status"
    puts "=" * 40

    total_experiences = Experience.count
    approved_experiences = Experience.approved.count
    vectorized_experiences = ExperienceVector.count

    puts "Total experiences: #{total_experiences}"
    puts "Approved experiences: #{approved_experiences}"
    puts "Vectorized experiences: #{vectorized_experiences}"

    if total_experiences.positive?
      completion_percentage = (vectorized_experiences.to_f / total_experiences * 100).round(1)
      puts "Completion: #{completion_percentage}%"
    end

    # Check vocabulary status
    begin
      vocabulary_size = VectorizationService.current_vocabulary.length
      puts "Vocabulary size: #{vocabulary_size} terms"
    rescue StandardError => e
      puts "Vocabulary: Not available (#{e.message})"
    end

    # Check for outdated vectors
    outdated_count = 0
    ExperienceVector.includes(:experience).find_each do |vector|
      outdated_count += 1 if vector.needs_regeneration?(vector.experience)
    end

    puts "Outdated vectors: #{outdated_count}"

    if vectorized_experiences.zero?
      puts "\n⚠️  Vector search not ready. Run: rails vector_search:initialize"
    elsif outdated_count.positive?
      puts "\n⚠️  Some vectors are outdated. Run: rails vector_search:refresh"
    else
      puts "\n✅ Vector search system is ready!"
    end
  end

  desc "Refresh outdated vectors"
  task refresh: :environment do
    puts "🔄 Refreshing outdated vectors..."

    outdated_vectors = []
    ExperienceVector.includes(:experience).find_each do |vector|
      outdated_vectors << vector if vector.needs_regeneration?(vector.experience)
    end

    if outdated_vectors.empty?
      puts "✅ All vectors are up to date!"
      next
    end

    puts "📊 Found #{outdated_vectors.length} outdated vectors"

    outdated_vectors.each do |vector|
      VectorizeExperienceJob.perform_later(vector.experience_id, force_regeneration: true)
    end

    puts "✅ Refresh jobs queued for #{outdated_vectors.length} experiences"
  end

  desc "Rebuild entire vector search index (force regenerate all vectors)"
  task rebuild: :environment do
    puts "🔨 Rebuilding entire vector search index..."

    next unless confirm_operation("This will regenerate ALL vectors.", nil, "❌ Rebuild cancelled")

    # Clear existing vectors
    puts "🗑️  Clearing existing vectors..."
    ExperienceVector.delete_all

    # Clear caches
    Rails.cache.delete("search_vocabulary")
    Rails.cache.delete("document_frequencies")
    Rails.cache.delete_matched("search/*")

    # Queue batch vectorization with force regeneration
    total_experiences = Experience.count
    puts "📊 Queuing vectorization for #{total_experiences} experiences..."

    BatchVectorizeExperiencesJob.perform_later(
      batch_size: 50,
      force_regeneration: true,
      approved_only: false
    )

    puts "✅ Rebuild started. Check logs for progress."
  end

  desc "Test vector search with a sample query"
  task :test, [ :query ] => :environment do |_t, args|
    query = args[:query] || "space"
    puts "🔍 Testing vector search with query: '#{query}'"
    puts "=" * 50

    begin
      results = ExperienceSearchService.search(query, limit: 10)

      if results.empty?
        puts "❌ No results found"
      else
        puts "✅ Found #{results.length} results:"
        puts

        results.each_with_index do |experience, index|
          puts "#{index + 1}. #{experience.title}"
          puts "   Author: #{experience.author || 'Unknown'}"
          puts "   Description: #{experience.description&.truncate(100) || 'No description'}"
          puts
        end
      end
    rescue StandardError => e
      puts "❌ Search failed: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end

  desc "Clear all vector search data and caches"
  task clear: :environment do
    puts "🗑️  Clearing vector search data..."

    next unless confirm_operation("This will delete ALL vector data.", nil, "❌ Clear cancelled")

    # Delete all vectors
    deleted_count = ExperienceVector.count
    ExperienceVector.delete_all

    # Clear caches
    Rails.cache.delete("search_vocabulary")
    Rails.cache.delete("document_frequencies")
    Rails.cache.delete_matched("search/*")

    puts "✅ Cleared #{deleted_count} vectors and all related caches"
  end
end
