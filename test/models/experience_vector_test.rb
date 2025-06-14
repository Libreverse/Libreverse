# frozen_string_literal: true

require "test_helper"

class ExperienceVectorTest < ActiveSupport::TestCase
  setup do
    ExperienceVector.delete_all # Ensure clean slate for unique constraint
    Experience.delete_all # Also clear experiences to avoid FK issues
    Account.delete_all # Also clear accounts to avoid FK issues
    # Recreate needed accounts and experiences for tests
    password_hash = Argon2::Password.create("password")
    @account_one = Account.create!(username: "testuser1", password_hash: password_hash, status: 2)
    @account_two = Account.create!(username: "testuser2", password_hash: password_hash, status: 2)
    @experience = Experience.create!(title: "First Experience", description: "desc", account: @account_one, approved: true)
    @experience_two = Experience.create!(title: "Second Experience", description: "desc", account: @account_two, approved: true)
    @vector_data = [ 0.1, 0.2, 0.3, 0.4, 0.5 ]
    @content_hash = "test_hash_123"
  end

  test "creates valid experience vector" do
    vector = ExperienceVector.new(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    assert vector.valid?
    assert vector.save
  end

  test "requires experience association" do
    vector = ExperienceVector.new(
      vector_data: @vector_data,
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    assert_not vector.valid?
    assert_includes vector.errors[:experience], "must exist"
  end

  test "requires vector_data" do
    vector = ExperienceVector.new(
      experience: @experience,
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    assert_not vector.valid?
    assert_includes vector.errors[:vector_data], "can't be blank"
  end

  test "requires vector_hash" do
    vector = ExperienceVector.new(
      experience: @experience,
      vector_data: @vector_data,
      generated_at: Time.current,
      version: 1
    )

    assert_not vector.valid?
    assert_includes vector.errors[:vector_hash], "can't be blank"
  end

  test "requires generated_at" do
    vector = ExperienceVector.new(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: @content_hash,
      version: 1
    )

    assert_not vector.valid?
    assert_includes vector.errors[:generated_at], "can't be blank"
  end

  test "requires version" do
    vector = ExperienceVector.new(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: nil
    )

    assert_not vector.valid?
    assert_includes vector.errors[:version], "can't be blank"
  end

  test "version must be positive" do
    vector = ExperienceVector.new(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 0
    )

    assert_not vector.valid?
    assert_includes vector.errors[:version], "must be greater than 0"
  end

  test "enforces unique vector_hash per experience" do
    # Create first vector
    ExperienceVector.create!(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    # Try to create second vector with same hash for same experience
    duplicate_vector = ExperienceVector.new(
      experience: @experience,
      vector_data: [ 0.6, 0.7, 0.8 ],
      vector_hash: @content_hash, # Same hash
      generated_at: Time.current,
      version: 2
    )

    assert_not duplicate_vector.valid?
    assert_includes duplicate_vector.errors[:vector_hash], "has already been taken"
  end

  test "allows same vector_hash for different experiences" do
    experience2 = @experience_two

    # Create first vector
    ExperienceVector.create!(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    # Create second vector with same hash but different experience
    vector2 = ExperienceVector.new(
      experience: experience2,
      vector_data: [ 0.6, 0.7, 0.8 ],
      vector_hash: @content_hash, # Same hash but different experience
      generated_at: Time.current,
      version: 1
    )

    assert vector2.valid?
    assert vector2.save
  end

  test "serializes vector_data as JSON array" do
    vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    # Reload and check serialization
    vector.reload
    assert_equal @vector_data, vector.vector_data
    assert vector.vector_data.is_a?(Array)
  end

  test "calculates cosine similarity with array" do
    vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: [ 1.0, 2.0, 3.0 ],
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    other_vector = [ 2.0, 4.0, 6.0 ] # Proportional vector
    similarity = vector.cosine_similarity(other_vector)

    assert_in_delta 1.0, similarity, 0.001 # Should be 1.0 for proportional vectors
  end

  test "calculates cosine similarity with JSON string" do
    vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: [ 1.0, 2.0, 3.0 ],
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    other_vector_json = "[2.0, 4.0, 6.0]"
    similarity = vector.cosine_similarity(other_vector_json)

    assert_in_delta 1.0, similarity, 0.001
  end

  test "handles nil vector in similarity calculation" do
    vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: [ 1.0, 2.0, 3.0 ],
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    similarity = vector.cosine_similarity(nil)
    assert_equal 0.0, similarity
  end

  test "handles empty vector in similarity calculation" do
    vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: [ 1.0, 2.0, 3.0 ],
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    similarity = vector.cosine_similarity([])
    assert_equal 0.0, similarity
  end

  test "generates content hash correctly" do
    title = "Test Title"
    description = "Test Description"
    author = "Test Author"

    hash1 = ExperienceVector.generate_content_hash(title, description, author)
    hash2 = ExperienceVector.generate_content_hash(title, description, author)

    assert_equal hash1, hash2, "Same content should generate same hash"
    assert hash1.length == 32, "Should generate MD5 hash"
  end

  test "generates different hashes for different content" do
    hash1 = ExperienceVector.generate_content_hash("Title1", "Desc1", "Author1")
    hash2 = ExperienceVector.generate_content_hash("Title2", "Desc2", "Author2")

    assert_not_equal hash1, hash2
  end

  test "handles nil values in content hash generation" do
    hash = ExperienceVector.generate_content_hash(nil, "Description", nil)
    assert hash.is_a?(String)
    assert hash.length == 32
  end

  test "detects when regeneration is needed" do
    # Create vector with specific content hash
    original_title = @experience.title
    original_description = @experience.description
    original_author = @experience.author

    original_hash = ExperienceVector.generate_content_hash(
      original_title, original_description, original_author
    )

    vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: original_hash,
      generated_at: Time.current,
      version: 1
    )

    # Vector should not need regeneration initially
    assert_not vector.needs_regeneration?(@experience)

    # Change experience content
    @experience.update!(title: "New Title")

    # Vector should now need regeneration
    assert vector.needs_regeneration?(@experience)
  end

  test "detects regeneration not needed when content unchanged" do
    # Create vector with current content hash
    current_hash = ExperienceVector.generate_content_hash(
      @experience.title, @experience.description, @experience.author
    )

    vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: current_hash,
      generated_at: Time.current,
      version: 1
    )

    assert_not vector.needs_regeneration?(@experience)
  end

  test "handles experience with missing content in regeneration check" do
    # Create experience with minimal content
    empty_experience = Experience.create!(
      title: "Empty",
      description: "",
      author: nil,
      account: @account_one
    )

    hash = ExperienceVector.generate_content_hash("Empty", "", nil)

    vector = ExperienceVector.create!(
      experience: empty_experience,
      vector_data: @vector_data,
      vector_hash: hash,
      generated_at: Time.current,
      version: 1
    )

    assert_not vector.needs_regeneration?(empty_experience)
  end

  test "updates version when vector is updated" do
    vector = ExperienceVector.create!(
      experience: @experience,
      vector_data: @vector_data,
      vector_hash: @content_hash,
      generated_at: Time.current,
      version: 1
    )

    # Update vector
    new_vector_data = [ 0.6, 0.7, 0.8, 0.9, 1.0 ]
    vector.update!(
      vector_data: new_vector_data,
      version: vector.version + 1
    )

    assert_equal 2, vector.version
    assert_equal new_vector_data, vector.vector_data
  end

  teardown do
# With transactional tests, this is usually unnecessary.
# If explicit cleanup is required:
ExperienceVector.destroy_all
Experience.destroy_all
Account.destroy_all
  end
end
