namespace :users do
  desc "Create a test user with a known pwned password"
  task create_test_user: :environment do
    require 'sequel'
    
    # Use a common pwned password (definitely in the database)
    username = "testuser"
    password = "password123"
    
    # Get DB connection
    db = Sequel.postgres(extensions: :activerecord_connection, keep_reference: false)
    
    # Create an account
    # Check if the user already exists
    if db.from(:accounts).where(username: username).empty?
      # Create the user
      puts "Creating test user '#{username}' with a known pwned password..."
      
      # Hash the password with Argon2
      argon2 = Argon2::Password.new(t_cost: 2, m_cost: 16, secret: nil)
      password_hash = argon2.create(password)
      
      # Insert the account
      account_id = db.from(:accounts).insert(
        username: username,
        password_hash: password_hash,
        status: 2, # verified
        password_changed_at: Time.now
      )
      
      puts "Created test user with ID #{account_id}"
      puts "Username: #{username}"
      puts "Password: #{password}"
      puts "This password is pwned and will trigger the password change requirement"
    else
      puts "User '#{username}' already exists"
    end
  end
end 