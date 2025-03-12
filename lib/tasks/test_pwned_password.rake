namespace :test do
  desc "Test the pwned password API functionality"
  task pwned_password: :environment do
    # Make sure we have the pwned gem
    require 'pwned'
    
    # Test with a known compromised password
    test_password = "password123"
    
    puts "Testing pwned password API with password: #{test_password}"
    puts "=" * 50
    
    # Test with the pwned_password gem directly
    begin
      puts "\nTesting with pwned_password gem directly:"
      checker = Pwned::Password.new(test_password)
      puts "Is pwned? #{checker.pwned?}"
      puts "Times found in breaches: #{checker.times_pwned}"
    rescue => e
      puts "Error with direct pwned_password check: #{e.class} - #{e.message}"
    end
    
    # Test with a Rodauth instance
    begin
      puts "\nTesting with Rodauth instance:"
      rodauth = RodauthApp.rodauth.allocate
      
      puts "Is password pwned? #{rodauth.password_pwned?(test_password)}"
      
      # Try to access the pwned_count if available
      if rodauth.respond_to?(:pwned_count)
        puts "Pwned count: #{rodauth.pwned_count(test_password)}"
      else
        puts "Note: pwned_count method is not available"
      end
    rescue => e
      puts "Error with Rodauth pwned check: #{e.class} - #{e.message}"
    end
    
    # Test with the actual login flow simulation
    begin
      puts "\nSimulating login flow:"
      # Create a request-like context
      rodauth = RodauthApp.rodauth.allocate
      
      # Set up the parameters like they would be in a login request
      def rodauth.param(key)
        @params ||= { 'login' => 'testuser', 'password' => 'password123' }
        @params[key]
      end
      
      def rodauth.param_or_nil(key)
        param(key)
      end
      
      # Test if the password would be considered pwned in this context
      puts "Is password pwned in flow context? #{rodauth.password_pwned?(rodauth.param('password'))}"
    rescue => e
      puts "Error with simulated login flow: #{e.class} - #{e.message}"
    end
    
    puts "\n" + "=" * 50
    puts "Test completed."
  end
end 