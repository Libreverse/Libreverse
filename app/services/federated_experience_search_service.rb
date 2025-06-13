# frozen_string_literal: true

# Service for searching experiences across federated Libreverse instances
# Uses link-exclusive federation for security
class FederatedExperienceSearchService
  class << self
    def search_across_instances(query, limit: 20)
      # Start with local results (using our secure local vectors)
      local_results = ExperienceSearchService.search(query, limit: limit)

      # Get federated announcement links that match the query
      federated_links = search_federated_announcements(query, limit: 5)

      # Combine results - local experiences + federated links
      all_results = local_results + federated_links
      all_results.uniq { |exp| exp.respond_to?(:federails_uri) ? exp.federails_uri : exp.activitypub_uri }
                 .first(limit)
    end

    def discover_libreverse_instances
      # Get domains from federated announcements
      FederatedAnnouncement.distinct.pluck(:source_domain)
    end

    private

    def search_federated_announcements(query, limit: 5)
      return [] if query.blank?

      # Enhanced search through announced experience metadata with ranking
      query_words = query.downcase.split

      announcements = FederatedAnnouncement.where(
        "LOWER(title) LIKE ?",
        "%#{query.downcase}%"
      ).recent.limit(limit * 2) # Get more to allow for ranking

      # Apply similarity ranking to federated announcements (like local search)
      ranked_announcements = announcements.map do |announcement|
        score = calculate_federated_similarity(announcement, query, query_words)
        { announcement: announcement, similarity: score }
      end

      # Sort by similarity and take top results
      ranked_announcements.sort_by { |item| -item[:similarity] }
                          .first(limit)
                          .map { |item| item[:announcement].federated_experience_link }
    end

    # Calculate similarity score for federated announcements (similar to local search logic)
    def calculate_federated_similarity(announcement, query, query_words)
      return 0.0 if announcement.title.blank?

      score = 0.0
      title_lower = announcement.title.downcase
      query_lower = query.downcase

      # Title exact match (highest score)
      if title_lower == query_lower
        score += 1.0
      # Title starts with query (high score)
      elsif title_lower.start_with?(query_lower)
        score += 0.8
      # Title contains query (medium score)
      elsif title_lower.include?(query_lower)
        score += 0.6
      end

      # Word overlap scoring (like local search)
      title_words = title_lower.split
      word_overlap = (title_words & query_words).length
      total_words = (title_words | query_words).length

      score += (word_overlap.to_f / total_words) * 0.4 if total_words.positive?

      # Recency bonus (prefer recent announcements)
      days_ago = (Time.current - announcement.announced_at) / 1.day
      recency_score = Math.exp(-days_ago / 30.0) * 0.2 # 30-day half-life
      score += recency_score

      score
    end
  end
end
