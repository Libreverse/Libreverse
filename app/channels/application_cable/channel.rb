# frozen_string_literal: true
# shareable_constant_value: literal

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    include CableReady::Broadcaster
  end
end
