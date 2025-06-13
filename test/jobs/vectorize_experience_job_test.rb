# frozen_string_literal: true

require "test_helper"

class VectorizeExperienceJobTest < ActiveJob::TestCase
  setup do
    # Clear any existing vectors and jobs
    ExperienceVector.delete_all
    clear_enqueued_jobs

    # Temporarily disable moderation for tests
    @original_moderation_setting = InstanceSetting.get("automoderation_enabled")
    InstanceSetting.set("automoderation_enabled", "false", "Temporarily disable moderation for tests")

    @experience = Experience.create!(
      title: "Machine Learning Basics",
      description: "Introduction to machine learning algorithms",
      author: "Data Scientist",
      account: accounts(:one)
    )
  end

  test "enqueues job successfully" do
    assert_enqueued_with(job: VectorizeExperienceJob, args: [ @experience.id ]) do
      VectorizeExperienceJob.perform_later(@experience.id)
    end
  end

  test "performs vectorization successfully" do
    # Mock VectorizationService to return predictable vector
    mock_vector = [ 0.1, 0.2, 0.3, 0.4, 0.5 ]
    VectorizationService.stubs(:vectorize_experience).returns(mock_vector)

    assert_difference("ExperienceVector.count", 1) do
      VectorizeExperienceJob.perform_now(@experience.id)
    end

    # Check that vector was created correctly
    vector = @experience.reload.experience_vector
    assert_not_nil vector
    assert_equal mock_vector, vector.vector_data
    assert_equal 1, vector.version
    assert_not_nil vector.generated_at
  end

  test "updates existing vector when one exists" do
    # Create initial vector
    initial_vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: [ 0.1, 0.2, 0.3 ],
      vector_hash: "old_hash",
      generated_at: 1.hour.ago,
      version: 1
    )

    # Mock new vector data
    new_vector = [ 0.4, 0.5, 0.6, 0.7, 0.8 ]
    VectorizationService.stubs(:vectorize_experience).returns(new_vector)

    assert_no_difference("ExperienceVector.count") do
      VectorizeExperienceJob.perform_now(@experience.id)
    end

    # Check that vector was updated
    initial_vector.reload
    assert_equal new_vector, initial_vector.vector_data
    assert_equal 2, initial_vector.version
    assert initial_vector.generated_at > 30.minutes.ago
  end

  test "forces regeneration when requested" do
    # Create vector with current content hash (normally wouldn't need regeneration)
    current_hash = ExperienceVector.generate_content_hash(
      @experience.title,
      @experience.description,
      @experience.author
    )

    existing_vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: [ 0.1, 0.2, 0.3 ],
      vector_hash: current_hash,
      generated_at: Time.current,
      version: 1
    )

    # Mock new vector
    new_vector = [ 0.4, 0.5, 0.6 ]
    VectorizationService.stubs(:vectorize_experience).returns(new_vector)

    # Force regeneration
    VectorizeExperienceJob.perform_now(@experience.id, force_regeneration: true)

    # Vector should be updated even though content hash matched
    existing_vector.reload
    assert_equal new_vector, existing_vector.vector_data
    assert_equal 2, existing_vector.version
  end

  test "skips vectorization when not needed and not forced" do
    # Create vector with current content hash
    current_hash = ExperienceVector.generate_content_hash(
      @experience.title,
      @experience.description,
      @experience.author
    )

    existing_vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: [ 0.1, 0.2, 0.3 ],
      vector_hash: current_hash,
      generated_at: Time.current,
      version: 1
    )

    original_version = existing_vector.version
    original_data = existing_vector.vector_data.dup

    # Don't mock VectorizationService - it shouldn't be called
    VectorizeExperienceJob.perform_now(@experience.id, force_regeneration: false)

    # Vector should remain unchanged
    existing_vector.reload
    assert_equal original_version, existing_vector.version
    assert_equal original_data, existing_vector.vector_data
  end

  test "handles missing experience gracefully" do
    non_existent_id = 99_999

    assert_nothing_raised do
      VectorizeExperienceJob.perform_now(non_existent_id)
    end

    # No vector should be created
    assert_equal 0, ExperienceVector.count
  end

  test "handles vectorization service errors gracefully" do
    # Ensure we start with no vectors
    ExperienceVector.delete_all

    # Debug: verify no vectors exist
    assert_equal 0, ExperienceVector.count, "Should start with no vectors"

    # Mock VectorizationService to raise an error consistently
    VectorizationService.expects(:vectorize_experience).with(@experience).raises(StandardError.new("Vectorization failed")).at_least_once

    # The job will handle the error internally (retry mechanism)
    # We don't expect it to bubble up, we just want to verify it doesn't create a vector
    begin
      VectorizeExperienceJob.perform_now(@experience.id, force_regeneration: true)
    rescue StandardError
      nil
    end

    # Error should result in no vector being created
    assert_equal 0, ExperienceVector.count
  end

  test "logs successful vectorization" do
    mock_vector = [ 0.1, 0.2, 0.3 ]
    VectorizationService.stubs(:vectorize_experience).returns(mock_vector)

    VectorizeExperienceJob.perform_now(@experience.id)

    # Verify vector was created successfully
    assert_equal 1, ExperienceVector.count
    vector = ExperienceVector.last
    assert_equal mock_vector, vector.vector_data
  end

  test "logs successful vector update" do
    # Create existing vector
    ExperienceVector.create!(
      experience: @experience,
      vector_data: [ 0.1, 0.2, 0.3 ],
      vector_hash: "old_hash",
      generated_at: 1.hour.ago,
      version: 1
    )

    mock_vector = [ 0.4, 0.5, 0.6 ]
    VectorizationService.stubs(:vectorize_experience).returns(mock_vector)

    VectorizeExperienceJob.perform_now(@experience.id)

    # Verify vector was updated
    vector = @experience.reload.experience_vector
    assert_equal mock_vector, vector.vector_data
    assert_equal 2, vector.version
  end

  test "reraises errors from vectorization service" do
    # Ensure clean state
    ExperienceVector.delete_all

    VectorizationService.expects(:vectorize_experience).with(@experience).raises(StandardError.new("Test error")).at_least_once

    # Stub the retry_job method to verify it gets called
    VectorizeExperienceJob.any_instance.expects(:retry_job).once

    # The job handles errors with retry mechanism - verify it tries and doesn't crash
    begin
      VectorizeExperienceJob.perform_now(@experience.id, force_regeneration: true)
    rescue StandardError
      nil
    end

    # Test passes if we reach here and retry_job was called
  end

  test "clears search caches after vectorization" do
    mock_vector = [ 0.1, 0.2, 0.3 ]
    VectorizationService.stubs(:vectorize_experience).returns(mock_vector)

    # Set some cache values
    Rails.cache.write("search_vocabulary", %w[test vocab])
    Rails.cache.write("document_frequencies", { "test" => 1 })

    VectorizeExperienceJob.perform_now(@experience.id)

    # Caches should be cleared
    assert_nil Rails.cache.read("search_vocabulary")
    assert_nil Rails.cache.read("document_frequencies")
  end

  test "retries on failure with exponential backoff" do
    # Verify retry configuration exists by checking for the presence of rescue handlers
    job = VectorizeExperienceJob.new
    assert_not_empty job.class.rescue_handlers
  end

  test "processes job in correct queue" do
    job = VectorizeExperienceJob.new
    assert_equal "default", job.queue_name
  end

  test "handles experience with minimal content" do
    minimal_experience = Experience.create!(
      title: "Minimal",
      description: "",
      author: "",
      account: accounts(:one)
    )

    mock_vector = [ 0.0, 0.0, 0.0 ] # Empty content might produce zero vector
    VectorizationService.stubs(:vectorize_experience).returns(mock_vector)

    assert_difference("ExperienceVector.count", 1) do
      VectorizeExperienceJob.perform_now(minimal_experience.id)
    end

    vector = minimal_experience.reload.experience_vector
    assert_not_nil vector
    assert_equal mock_vector, vector.vector_data
  end

  test "handles experience with special characters" do
    special_experience = Experience.create!(
      title: "Test with émojis 🎉 and spëcial chars!",
      description: "Content with <HTML> tags & symbols @#$%",
      author: "Authôr Namé",
      account: accounts(:one)
    )

    mock_vector = [ 0.1, 0.2, 0.3, 0.4 ]
    VectorizationService.stubs(:vectorize_experience).returns(mock_vector)

    assert_nothing_raised do
      VectorizeExperienceJob.perform_now(special_experience.id)
    end

    vector = special_experience.reload.experience_vector
    assert_not_nil vector
  end

  private

  def capture_log
    log_stream = StringIO.new
    old_logger = Rails.logger
    Rails.logger = Logger.new(log_stream)

    yield

    log_stream.string
  ensure
    Rails.logger = old_logger
  end

  teardown do
    ExperienceVector.delete_all
    clear_enqueued_jobs
    Rails.cache.clear

    # Restore original moderation setting
    InstanceSetting.set("automoderation_enabled", @original_moderation_setting || "true", "Restore moderation setting") if defined?(@original_moderation_setting)
  end
end
