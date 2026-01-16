# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Test-only patches to stabilize TiDB/Trilogy interactions during fixture loading.
# Goal: avoid protocol-level TRILOGY_TRUNCATED_PACKET errors caused by batch execution
# and SET OPTION commands when loading large fixture sets.

if Rails.env.test? && ENV.fetch("TRILOGY_PACKET_PATCH") { "1" } == "1"
  module ActiveRecord
    module ConnectionAdapters
      class TrilogyAdapter
        # Disable foreign key checks using MySQL/TiDB session variable to avoid bulk SET OPTION packets.
        def disable_referential_integrity
          execute("SET FOREIGN_KEY_CHECKS=0")
          yield
        ensure
          begin
            execute("SET FOREIGN_KEY_CHECKS=1")
          rescue StandardError
            nil
          end
        end

        module PatchedBatchExecution
          # Execute each statement individually to avoid packet truncation issues.
          def execute_batch(statements, name = nil)
            Array(statements).each { |sql| execute(sql, name) }
          end
        end

        prepend PatchedBatchExecution
      end
    end
  end
end
