derived_key = ActiveSupport::KeyGenerator.new(
               Rails.application.secret_key_base, iterations: 1000
             ).generate_key("lockbox", 32)            # 32 raw bytes

Lockbox.master_key = derived_key.unpack1("H*")        # convert to hex