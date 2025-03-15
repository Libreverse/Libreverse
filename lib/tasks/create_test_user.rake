namespace :users do
  desc "Create a test user with a known pwned password"
  task create_test_user: :environment do
    # Use a common pwned password (definitely in the database)
    username = "testuser"
    password = "password123"

    # Check if the user already exists
    if Account.where(username: username).empty?
      # Create the user
      puts "Creating test user '#{username}' with a known pwned password..."

      # Hash the password with Argon2
      argon2 = Argon2::Password.new(t_cost: 2, m_cost: 16, secret: nil)
      password_hash = argon2.create(password)

      # Create the account using the model
      account = Account.new(
        username: username,
        password_hash: password_hash,
        status: 2, # verified
        password_changed_at: Time.zone.now
      )

      if account.save
        puts "Created test user with ID #{account.id}"
        puts "Username: #{username}"
        puts "Password: #{password}"
        puts "This password is pwned and will trigger the password change requirement"
      else
        puts "Failed to create user: #{account.errors.full_messages.join(', ')}"
      end
    else
      puts "User '#{username}' already exists"
    end
  end
end
