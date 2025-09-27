# frozen_string_literal: true

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
                sqlite_pct = Integer(ENV.fetch("THREAD_BUDGET_SQLITE_PCT") { "30" })
                sq_pct     = Integer(ENV.fetch("THREAD_BUDGET_SOLID_QUEUE_PCT") { "10" })

                sum = app_pct + sqlite_pct + sq_pct
                return { app: app_pct, sqlite: sqlite_pct, sq: sq_pct } if sum <= 100 && sum.positive?

                # Normalize if sum > 100 or 0
                sum = 100 if sum <= 0
                {
                  app: (app_pct * 100.0 / sum),
                  sqlite: (sqlite_pct * 100.0 / sum),
                  sq: (sq_pct * 100.0 / sum)
                }
        rescue StandardError
                { app: 50.0, sqlite: 30.0, sq: 10.0 }
        end

        def compute
                total = total_threads * 10
                pct   = percentages

                # Convert percentages to integer thread counts, rounding down for safety
                app_threads    = [ (total * pct[:app]    / 100.0).floor, 1 ].max
                sqlite_threads = [ (total * pct[:sqlite] / 100.0).floor, 1 ].max
                sq_total       = [ (total * pct[:sq]     / 100.0).floor, 1 ].max

                # Solid Queue processes: spread across cores without starving others
                # Default to roughly one process per 4 cores (min 1), but never more than sq_total
                default_sq_procs = [ [ (total / 4.0).floor, 1 ].max, sq_total ].min
                sq_processes = Integer(ENV.fetch("SOLID_QUEUE_PROCESSES") { default_sq_procs.to_s })
                sq_processes = 1 if sq_processes < 1

                # Threads per SQ process (at least 1), rounded down
                sq_threads_per_proc = [ (sq_total / sq_processes), 1 ].max

                                # Split the web-facing budget (previously all Passenger) between Passenger processes
                                # and Nginx worker_processes. Default to a 50/50 split with minimums of 1.
                                web_total = app_threads
                                passenger_pct = begin
                                                                    Integer(ENV.fetch("THREAD_BUDGET_PASSENGER_PCT") { "50" })
                                rescue StandardError
                                                                    50
                                end
                                passenger_procs = [ (web_total * passenger_pct / 100.0).floor, 1 ].max
                                nginx_workers   = [ web_total - passenger_procs, 1 ].max

                {
                  total: total,
                  app_threads: app_threads,
                  sqlite_threads: sqlite_threads,
                  sq_total_threads: sq_total,
                  sq_processes: sq_processes,
                  sq_threads_per_process: sq_threads_per_proc,
                  web_total: web_total,
                  passenger_procs: passenger_procs,
                  nginx_workers: nginx_workers
                }
        end

        # Returns allocated threads for a given component key (:app, :sqlite, :sq)
        def allocated_threads(component)
                comp = component.to_s
                b = compute
                case comp
                when "app"
                        b[:app_threads]
                when "sqlite"
                        b[:sqlite_threads]
                when "sq", "solid_queue", "solidqueue", "solid-queue"
                        b[:sq_total_threads]
                else
                        0
                end
        end

        # Optional human summary hash for richer logging/UIs
        def details
                b = compute
                {
                  total_threads: b[:total],
                  app: { threads: b[:app_threads] },
                  sqlite: { threads: b[:sqlite_threads] },
                  web: {
                    total: b[:web_total],
                    passenger_procs: b[:passenger_procs],
                    nginx_workers: b[:nginx_workers]
                  },
                  solid_queue: {
                    total_threads: b[:sq_total_threads],
                    processes: b[:sq_processes],
                    threads_per_process: b[:sq_threads_per_process]
                  }
                }
        end

        # Sum of allocated threads across components (may exceed total due to per-component minimums)
        def allocation_sum
                b = compute
                b[:app_threads] + b[:sqlite_threads] + b[:sq_total_threads]
        end

        # True if allocated threads exceed total threads (expected when enforcing minimums)
        def oversubscribed?
                allocation_sum > total_threads
        end

        def export_env!
                b = compute
                ENV["THREADS_TOTAL"]                   = b[:total].to_s
                ENV["APP_THREADS_BUDGET"]              = b[:app_threads].to_s
                ENV["SQLITE_THREADS_BUDGET"]           = b[:sqlite_threads].to_s
                ENV["SOLID_QUEUE_THREADS_TOTAL"]       = b[:sq_total_threads].to_s
                ENV["SOLID_QUEUE_PROCESSES"]           = b[:sq_processes].to_s
                ENV["SOLID_QUEUE_THREADS_PER_PROCESS"] = b[:sq_threads_per_process].to_s
                ENV["WEB_TOTAL_THREADS"]               = b[:web_total].to_s
                ENV["PASSENGER_PROCESSES_TARGET"]      = b[:passenger_procs].to_s
                ENV["NGINX_WORKER_PROCESSES"]          = b[:nginx_workers].to_s

                # Common hints some libraries read
                ENV["RAILS_MAX_THREADS"] ||= b[:app_threads].to_s
        rescue StandardError => e
                warn "ThreadBudget export failed: #{e.message}"
        end
end

ThreadBudget.export_env!
