# frozen_string_literal: true

require "test_helper"

class BatchVectorizeExperiencesJobTest < ActiveJob::TestCase
  setup do
    Experience.delete_all
    ExperienceVector.delete_all
    clear_enqueued_jobs

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
    assert_enqueued_jobs 5, only: VectorizeExperienceJob do
      BatchVectorizeExperiencesJob.perform_now(batch_size: 2)
    end
  end

  test "handles empty experience set gracefully" do
    Experience.delete_all

    assert_nothing_raised do
      BatchVectorizeExperiencesJob.perform_now(batch_size: 10)
    end
  end

  test "logs batch processing progress" do
    logs = []
    old_logger = Rails.logger
    Rails.logger = Logger.new(StringIO.new).tap do |logger|
      logger.define_singleton_method(:info) do |message|
        logs << message
        super(message)
      end
    end

    BatchVectorizeExperiencesJob.perform_now(batch_size: 2)

    assert logs.any? { |log| log.include?("batch") }
  ensure
    Rails.logger = old_logger
  end
end
