# frozen_string_literal: true

require "test_helper"

class BatchVectorizeExperiencesJobTest < ActiveJob::TestCase
  setup do
    # Clean slate
    Experience.delete_all
    ExperienceVector.delete_all
    clear_enqueued_jobs

    # Create test experiences
    @experiences = []
    5.times do |i|
      @experiences << Experience.create!(
        title: "Experience #{i}",
        description: "Description for experience #{i}",
        author: "Author #{i}",
        account: accounts(:one),
        approved: true
      )
    end
  end

  test "enqueues batch vectorization job" do
    assert_enqueued_with(job: BatchVectorizeExperiencesJob) do
      BatchVectorizeExperiencesJob.perform_later(batch_size: 2)
    end
  end

  test "processes experiences in batches" do
    # Mock the individual vectorization job
    VectorizeExperienceJob.stubs(:perform_later)

    # Expect 5 individual jobs to be enqueued (one per experience)
    VectorizeExperienceJob.expects(:perform_later).times(5)

    BatchVectorizeExperiencesJob.perform_now(batch_size: 2)
  end

  test "respects batch size parameter" do
    VectorizeExperienceJob.method(:perform_later)
    call_count = 0

    VectorizeExperienceJob.stubs(:perform_later).with do |_experience_id, _options|
      call_count += 1
      true
    end

    BatchVectorizeExperiencesJob.perform_now(batch_size: 3)

    assert_equal @experiences.count, call_count
  end

  test "handles approved_only parameter" do
    # Create unapproved experience
    Experience.create!(
      title: "Unapproved Experience",
      description: "This should not be processed",
      author: "Hidden Author",
      account: accounts(:one),
      approved: false
    )

    VectorizeExperienceJob.stubs(:perform_later)

    # With approved_only: true, should only process approved experiences
    VectorizeExperienceJob.expects(:perform_later).times(@experiences.count)

    BatchVectorizeExperiencesJob.perform_now(
      batch_size: 10,
      approved_only: true
    )
  end

  test "processes all experiences when approved_only is false" do
    # Create unapproved experience
    Experience.create!(
      title: "Unapproved Experience",
      description: "This should be processed",
      author: "Hidden Author",
      account: accounts(:one),
      approved: false
    )

    VectorizeExperienceJob.stubs(:perform_later)

    # Should process all experiences (approved + unapproved)
    total_experiences = Experience.count
    VectorizeExperienceJob.expects(:perform_later).times(total_experiences)

    BatchVectorizeExperiencesJob.perform_now(
      batch_size: 10,
      approved_only: false
    )
  end

  test "passes force_regeneration parameter to individual jobs" do
    VectorizeExperienceJob.expects(:perform_later).with do |_experience_id, options|
      options[:force_regeneration] == true
    end.times(@experiences.count)

    BatchVectorizeExperiencesJob.perform_now(
      batch_size: 10,
      force_regeneration: true
    )
  end

  test "handles empty experience set gracefully" do
    Experience.delete_all

    assert_nothing_raised do
      BatchVectorizeExperiencesJob.perform_now(batch_size: 10)
    end
  end

  test "logs batch processing progress" do
    VectorizeExperienceJob.stubs(:perform_later)

    log_output = capture_log do
      BatchVectorizeExperiencesJob.perform_now(batch_size: 2)
    end

    assert_includes log_output, "batch"
    assert_includes log_output, @experiences.count.to_s
  end

  test "handles database errors gracefully" do
    # Mock database error
    Experience.stubs(:find_each).raises(ActiveRecord::StatementInvalid.new("Database error"))

    assert_raises(ActiveRecord::StatementInvalid) do
      BatchVectorizeExperiencesJob.perform_now(batch_size: 10)
    end
  end

  test "processes experiences with different batch sizes" do
    batch_sizes = [ 1, 2, 3, 10, 100 ]

    batch_sizes.each do |batch_size|
      VectorizeExperienceJob.stubs(:perform_later)
      VectorizeExperienceJob.expects(:perform_later).times(@experiences.count)

      assert_nothing_raised do
        BatchVectorizeExperiencesJob.perform_now(batch_size: batch_size)
      end
    end
  end

  test "retries on failure" do
    # Check retry configuration exists
    assert_includes BatchVectorizeExperiencesJob.retry_on_exceptions, StandardError
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
    clear_enqueued_jobs
    Experience.delete_all
    ExperienceVector.delete_all
  end
end
