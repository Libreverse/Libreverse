# typed: strict
# frozen_string_literal: true

module ExecJS
  sig { returns(T.untyped) }
  def self.runtime; end
  
  sig { params(runtime: T.untyped).returns(T.untyped) }
  def self.runtime=(runtime); end
  
  module Runtimes
    class Node
    end
    
    sig { returns(Node) }
    def self.Node; end
  end
end
