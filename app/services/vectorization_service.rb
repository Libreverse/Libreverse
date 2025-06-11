# frozen_string_literal: true

class VectorizationService
  # Field weights for different parts of experience content
  FIELD_WEIGHTS = {
    title: 3.0,
    description: 2.0,
    author: 1.0
  }.freeze

  class << self
    # Generate TF-IDF vector for an experience
    def vectorize_experience(experience, vocabulary = nil)
      vocabulary ||= current_vocabulary

      # Extract and preprocess text from different fields
      field_terms = extract_field_terms(experience)

      # Calculate weighted term frequencies
      term_frequencies = calculate_weighted_tf(field_terms)

      # Get document frequencies for IDF calculation
      document_frequencies = get_document_frequencies(vocabulary)
      total_documents = Experience.approved.count

      # Generate TF-IDF vector
      generate_tfidf_vector(term_frequencies, document_frequencies, total_documents, vocabulary)
    end

    # Generate vector for a search query
    def vectorize_query(query_text, vocabulary = nil)
      vocabulary ||= current_vocabulary

      # Preprocess query text
      query_terms = TextPreprocessingService.preprocess(query_text)

      # Calculate term frequencies for query
      term_frequencies = calculate_term_frequencies(query_terms)

      # Get document frequencies for IDF calculation
      document_frequencies = get_document_frequencies(vocabulary)
      total_documents = Experience.approved.count

      # Generate TF-IDF vector
      generate_tfidf_vector(term_frequencies, document_frequencies, total_documents, vocabulary)
    end

    # Get the current vocabulary (cached)
    def current_vocabulary
      Rails.cache.fetch("search_vocabulary", expires_in: 1.hour) do
        calculate_vocabulary
      end
    end

    # Recalculate and cache vocabulary
    def refresh_vocabulary
      Rails.cache.delete("search_vocabulary")
      current_vocabulary
    end

    private

    # Extract terms from different fields of an experience
    def extract_field_terms(experience)
      {
        title: TextPreprocessingService.preprocess(experience.title),
        description: TextPreprocessingService.preprocess(experience.description),
        author: TextPreprocessingService.preprocess(experience.author)
      }
    end

    # Calculate weighted term frequencies across fields
    def calculate_weighted_tf(field_terms)
      term_frequencies = Hash.new(0.0)

      field_terms.each do |field, terms|
        weight = FIELD_WEIGHTS[field] || 1.0
        field_tf = calculate_term_frequencies(terms)

        field_tf.each do |term, frequency|
          term_frequencies[term] += frequency * weight
        end
      end

      term_frequencies
    end

    # Calculate simple term frequencies
    def calculate_term_frequencies(terms)
      return {} if terms.empty?

      term_counts = Hash.new(0)
      terms.each { |term| term_counts[term] += 1 }

      # Normalize by document length
      max_count = term_counts.values.max.to_f
      term_counts.transform_values { |count| count / max_count }
    end

    # Generate TF-IDF vector from term frequencies
    def generate_tfidf_vector(term_frequencies, document_frequencies, total_documents, vocabulary)
      vocabulary.map do |term|
        tf = term_frequencies[term] || 0.0
        df = document_frequencies[term] || 1

        # Calculate IDF with smoothing
        idf = Math.log(total_documents.to_f / df)

        tf * idf
      end
    end

    # Calculate document frequencies for all terms
    def get_document_frequencies(vocabulary)
      Rails.cache.fetch("document_frequencies", expires_in: 1.hour) do
        calculate_document_frequencies(vocabulary)
      end
    end

    # Calculate how many documents contain each term
    def calculate_document_frequencies(vocabulary)
      document_frequencies = Hash.new(0)

      Experience.approved.find_each do |experience|
        content = TextPreprocessingService.combine_experience_text(experience)
        terms = TextPreprocessingService.preprocess(content)
        unique_terms = terms.to_set

        vocabulary.each do |term|
          document_frequencies[term] += 1 if unique_terms.include?(term)
        end
      end

      document_frequencies
    end

    # Calculate the current vocabulary from all experiences
    def calculate_vocabulary
      all_terms = Set.new

      Experience.approved.find_each do |experience|
        content = TextPreprocessingService.combine_experience_text(experience)
        terms = TextPreprocessingService.preprocess(content)
        all_terms.merge(terms)
      end

      # Limit vocabulary size to most frequent terms
      term_frequencies = Hash.new(0)

      Experience.approved.find_each do |experience|
        content = TextPreprocessingService.combine_experience_text(experience)
        terms = TextPreprocessingService.preprocess(content)
        terms.each { |term| term_frequencies[term] += 1 }
      end

      # Keep top 1000 most frequent terms
      term_frequencies.sort_by { |_, freq| -freq }
                      .first(1000)
                      .map(&:first)
    end
  end
end
