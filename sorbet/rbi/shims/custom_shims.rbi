# typed: strict

# Shims for missing constants referenced by tapioca/annotations

module Spoom
  module Sorbet
    module Errors
      class Error; end
    end

    class Config; end
  end

  class ExecResult; end
  class Context; end
end

module ExecJS
  module Runtimes
    class Bun < ExecJS::ExternalRuntime; end
  end
end

module ExecJS
  class ExternalRuntime; end
end

class Sidekiq::SortedEntry; end
class Sidekiq::Process; end

module Mocha
  class Mock; end
end
