# frozen_string_literal: true

class VectorSearchService
  DIMENSIONS = 384 # Define the number of dimensions for the embeddings

  # Generates a normalized embedding for the given text
  def self.generate_embedding(text)
    return nil if text.blank?

    # Simple TF-IDF-like approach (replace with a real model in production)
    tokens = text.downcase.scan(/\w+/)
    return nil if tokens.empty?

    tf = tokens.tally
    vector = Array.new(DIMENSIONS, 0.0)

    unique_tokens = tokens.uniq
    i = 0
    while i < unique_tokens.size && i < DIMENSIONS
      token = unique_tokens[i]
      # Simple hash-based projection, not a real embedding
      vector[i % DIMENSIONS] += tf[token].to_f / tokens.size
      i += 1
    end

    # Normalize the vector (L2 normalization)
    norm = Math.sqrt(vector.map { |x| x**2 }.sum)
    return Array.new(DIMENSIONS, 0.0) if norm.zero? # Handle zero vector case

    vector.map { |x| x / norm }
  end

  # Updates or creates the embedding for an experience and syncs with VSS table
  def self.update_experience_embedding(experience)
    return unless experience

    text_to_embed = "#{experience.title} #{experience.description}"
    embedding = generate_embedding(text_to_embed)

    # Update the main experience record
    experience.update!(embedding: embedding&.to_json)

    # Sync with the VSS table
    if embedding
      insert_or_update_vss_embedding(experience.id, embedding)
    else
      delete_vss_embedding(experience.id) # Remove if embedding is nil
    end
    Rails.logger.info "VectorSearchService: Updated embedding for Experience ##{experience.id}"
  rescue StandardError => e
    Rails.logger.error "VectorSearchService: Error updating embedding for Experience ##{experience.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  # Searches for similar experiences using VSS
  def self.search_similar_experiences(query, limit: 10)
    Rails.logger.info "VectorSearchService: Searching for '#{query}' (limit: #{limit})"
    query_embedding = generate_embedding(query)

    unless query_embedding
      Rails.logger.warn "VectorSearchService: Could not generate embedding for query '#{query}'. Falling back to text search."
      return fallback_text_search(query, limit: limit)
    end

    begin
      # Ensure VSS extension is loaded
      begin
        Experience.connection.execute("SELECT vss_version();")
        vss_available = true
      rescue SQLite3::SQLException => e
        Rails.logger.warn "VectorSearchService: VSS extension not available or version check failed: #{e.message}. Falling back to text search."
        vss_available = false
      end

      return fallback_text_search(query, limit: limit) unless vss_available

      # Construct the VSS query parameters for vss_search_params
      # It expects a JSON object with 'vector' and 'k' (for limit)
      vss_parameters_json = { vector: query_embedding, k: limit }.to_json

      sql = <<~SQL
        SELECT experiences.*, experiences_vss.distance
        FROM experiences
        JOIN experiences_vss ON experiences_vss.rowid = experiences.id
        WHERE vss_search_params(experiences_vss.embedding, ?)
        ORDER BY experiences_vss.distance ASC
      SQL

      # The limit is handled by vss_search_params, so no separate SQL LIMIT clause needed here.
      results = Experience.find_by_sql([ sql, vss_parameters_json ])

      # Filter only approved experiences AFTER the VSS search
      # This is because VSS search operates on its own table.
      # We could also add an 'approved' column to the VSS table for direct filtering.
      approved_results = results.select(&:approved?)

      Rails.logger.info "VectorSearchService: Found #{approved_results.count} approved VSS results for '#{query}'."

      # If VSS results are fewer than limit, supplement with text search (optional)
      if approved_results.count < limit && (limit - approved_results.count).positive? # Ensure we need to fetch more
         Rails.logger.info "VectorSearchService: VSS results less than limit. Supplementing with text search."
         # Avoid re-fetching already found IDs
         excluded_ids = approved_results.map(&:id)
         text_results_limit = limit - approved_results.count

         text_results = fallback_text_search(query, limit: text_results_limit, excluded_ids: excluded_ids)
         # Combine and ensure uniqueness
         approved_results = (approved_results + text_results).uniq(&:id).first(limit)
      end

      return approved_results if approved_results.any?
    rescue SQLite3::SQLException => e
      Rails.logger.error "VectorSearchService: VSS search failed: #{e.message}. Falling back to text search."
      Rails.logger.error e.backtrace.join("\n")
      # Fallback to text search if VSS fails for any reason
    rescue StandardError => e
      Rails.logger.error "VectorSearchService: An unexpected error occurred during VSS search: #{e.message}. Falling back to text search."
      Rails.logger.error e.backtrace.join("\n")
    end

    fallback_text_search(query, limit: limit)
  end

  # Fallback text-based search if VSS is unavailable or fails
  def self.fallback_text_search(query, limit: 10, excluded_ids: [])
    Rails.logger.info "VectorSearchService: Performing fallback text search for '#{query}' (excluding #{excluded_ids.count} IDs)"
    search_terms = query.downcase.split(/\s+/).select(&:present?).first(5) # Limit terms
    return Experience.none if search_terms.empty?

    conditions = search_terms.map { "(LOWER(title) LIKE ? OR LOWER(description) LIKE ?)" }.join(" OR ")
    params = search_terms.flat_map { |term| [ "%#{term}%", "%#{term}%" ] }

    scope = Experience.approved
    scope = scope.where.not(id: excluded_ids) if excluded_ids.any?

    scope.where(conditions, *params)
         .order(created_at: :desc) # Or some other relevant order
         .limit(limit)
  end

  # --- VSS Table Synchronization Methods ---

  def self.insert_or_update_vss_embedding(experience_id, embedding_vector)
    embedding_json = embedding_vector.to_json

    begin
      # Try to update first
      update_sql = "UPDATE experiences_vss SET embedding = ? WHERE rowid = ?;"
      Experience.connection.execute(update_sql, [ embedding_json, experience_id ])

      # Since UPSERT is not available for VSS virtual tables, we'll use a delete-then-insert strategy.
      delete_vss_embedding(experience_id)
      insert_sql = "INSERT INTO experiences_vss (rowid, embedding) VALUES (?, ?);"
      Experience.connection.execute(insert_sql, [ experience_id, embedding_json ])

      Rails.logger.debug "VectorSearchService: Inserted/Updated VSS embedding for Experience ##{experience_id} (via delete-then-insert)"
    rescue StandardError => e
      # Log the specific error for insert/update
      Rails.logger.error "VectorSearchService: Failed to insert/update VSS embedding for Experience ##{experience_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def self.delete_vss_embedding(experience_id)
    sql = "DELETE FROM experiences_vss WHERE rowid = ?;"
    begin
      # Pass binds as an array
      Experience.connection.execute(sql, [ experience_id ])
      Rails.logger.debug "VectorSearchService: Deleted VSS embedding for Experience ##{experience_id}"
    rescue StandardError => e
      Rails.logger.error "VectorSearchService: Failed to delete VSS embedding for Experience ##{experience_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  # Method to rebuild the entire VSS table from scratch
  # Useful for initial population or if the VSS table gets out of sync
  def self.rebuild_vss_table
    Rails.logger.info "VectorSearchService: Rebuilding experiences_vss table..."
    Experience.connection.execute("DELETE FROM experiences_vss;")

    Experience.find_each do |experience|
      if experience.embedding.present?
        begin
          embedding_vector = JSON.parse(experience.embedding)
          insert_or_update_vss_embedding(experience.id, embedding_vector)
        rescue JSON::ParserError => e
          Rails.logger.error "VectorSearchService: Failed to parse embedding for Experience ##{experience.id} during rebuild: #{e.message}"
        end
      end
    end
    Rails.logger.info "VectorSearchService: Finished rebuilding experiences_vss table."
  end
end
