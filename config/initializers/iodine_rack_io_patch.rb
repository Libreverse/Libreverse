# frozen_string_literal: true

# This patch ensures that ActiveStorage's DiskService can work with Iodine's RackIO objects
# by adding compatibility with IO.copy_stream's string length setting operation
if defined?(Iodine) && defined?(Iodine::Base) && defined?(Iodine::Base::RackIO)
  Rails.logger.info "Applying Iodine RackIO patch for ActiveStorage compatibility"

  module Iodine
    module Base
      class RackIO
        # Add the ability to support IO.copy_stream, which attempts to set the length of the target string
        alias original_read read

        def read(length = nil, outbuf = nil)
          if outbuf.nil?
            original_read(length)
          else
            result = original_read(length)
            if result && outbuf.is_a?(String)
              outbuf.replace(result)
              outbuf
            else
              result
            end
          end
        end
      end
    end
  end
end
