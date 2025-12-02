# frozen_string_literal: true
# shareable_constant_value: literal

# Centralized thread budgeting to avoid overcommitting cores between components.
# Strategy: define percentage budgets per component, compute integer thread counts
# by rounding down for safety, and expose them via ENV for ERB configs to consume.

require "etc"

module ThreadBudget
  module_function

        def total_threads
                # Use logical processors; safe default of 2
                Etc.respond_to?(:nprocessors) ? Etc.nprocessors : 2
        rescue StandardError
                2
        end

        def percentages
                # Allow overrides via env; otherwise use conservative defaults that sum <= 100
                app_pct    = Integer(ENV.fetch("THREAD_BUDGET_APP_PCT") { "50" })
                dj_pct     = Integer(ENV.fetch("THREAD_BUDGET_DELAYED_JOB_PCT") { "50" })

                sum = app_pct + dj_pct
                return { app: app_pct, dj: dj_pct } if sum <= 100 && sum.positive?

                # Normalize if sum > 100 or 0
                sum = 100 if sum <= 0
                {
                  app: (app_pct * 100.0 / sum),
                  dj: (dj_pct * 100.0 / sum)
                }
        rescue StandardError
                { app: 50.0, dj: 50.0 }
        end

        def compute
                {
                  total: 1,
                  app_threads: 1,
                  sqlite_threads: 1,
                  dj_total_threads: 1,
                  dj_processes: 1,
                  dj_threads_per_process: 1,
                  web_total: 1,
                  passenger_procs: 1,
                  nginx_workers: 1
                }
        end

        # Returns allocated threads for a given component key (:app, :sqlite, :sq)
        def allocated_threads(_component)
                1
        end

        # Optional human summary hash for richer logging/UIs
        def details
                {
                  total_threads: 1,
                  app: { threads: 1 },
                  sqlite: { threads: 1 },
                  web: {
                    total: 1,
                    passenger_procs: 1,
                    nginx_workers: 1
                  },
                  delayed_job: {
                    total_threads: 1,
                    processes: 1,
                    threads_per_process: 1
                  }
                }
        end

        # Sum of allocated threads across components (may exceed total due to per-component minimums)
        def allocation_sum
                1
        end

        # True if allocated threads exceed total threads (expected when enforcing minimums)
        def oversubscribed?
                false
        end

        def export_env!
                ENV["THREADS_TOTAL"]                   = "1"
                ENV["APP_THREADS_BUDGET"]              = "1"
                ENV["SQLITE_THREADS_BUDGET"]           = "1"
                ENV["DELAYED_JOB_THREADS_TOTAL"]       = "1"
                ENV["DELAYED_JOB_PROCESSES"]           = "1"
                ENV["DELAYED_JOB_THREADS_PER_PROCESS"] = "1"
                ENV["WEB_TOTAL_THREADS"]               = "1"
                ENV["PASSENGER_PROCESSES_TARGET"]      = "1"
                ENV["NGINX_WORKER_PROCESSES"]          = "1"

                # Common hints some libraries read
                ENV["RAILS_MAX_THREADS"] ||= "1"
        rescue StandardError => e
                warn "ThreadBudget export failed: #{e.message}"
        end
end

ThreadBudget.export_env!
