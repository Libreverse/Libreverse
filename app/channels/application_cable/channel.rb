# frozen_string_literal: true
# shareable_constant_value: literal

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    include CableReady::Broadcaster
    
    private
    
    # Helper for creating signed stream names for AnyCable optimization
    def signed_stream_name(streamable)
      return streamable unless AnyCable.config.signed_streams.enabled?
      
      # Use Turbo's signed stream name helper if available, otherwise fall back to AnyCable's implementation
      if defined?(Turbo::Streams::TagHelper)
        # This would typically be used in views, but we can use it here too
        Turbo::Streams::TagHelper.signed_stream_name(streamable)
      else
        # Fallback implementation
        AnyCable::Streams.sign(streamable)
      end
    rescue
      # Fallback to regular stream name if signing fails
      streamable
    end
  end
end
