# frozen_string_literal: true
# shareable_constant_value: literal

namespace :jit do
  desc 'Run JIT warmup to pre-compile hot code paths (TruffleRuby)'
  task warmup: :environment do
    runs = ENV.fetch('RUNS', '3').to_i
    silent = ENV['SILENT'] == '1'

    puts "Running JIT warmup with #{runs} iterations per route..."
    puts "Ruby engine: #{RUBY_ENGINE} #{RUBY_VERSION}"
    puts "Session persistence: enabled (simulates single guest user)"
    puts

    stats = JitWarmupService.warmup(runs: runs, silent: silent)

    puts
    puts '=' * 60
    puts 'JIT Warmup Complete'
    puts '=' * 60
    puts "  Paths warmed:       #{stats[:paths]}"
    puts "  Total requests:     #{stats[:requests]}"
    puts "  Errors:             #{stats[:errors]}"
    puts "  Skipped:            #{stats[:skipped]}"
    puts "  Guest accounts:     #{stats[:guest_accounts_created]} created"
    puts "  Duration:           #{stats[:duration_ms]}ms"
    puts

    if stats[:skipped_reason]
      puts "Note: Warmup was skipped (#{stats[:skipped_reason]})"
      puts 'Set FORCE_JIT_WARMUP=1 to force warmup on non-TruffleRuby'
    end

    if stats[:guest_accounts_created] > 1
      puts "Warning: Multiple guest accounts created. Session persistence may not be working."
      puts "Expected: 1 guest account for all warmup requests."
    elsif stats[:guest_accounts_created] == 1
      puts "Note: 1 guest account created (will be cleaned up by scheduled job)"
    end
  end

  desc 'List all paths that will be warmed up'
  task paths: :environment do
    puts 'Public paths (always visible):'
    JitWarmupService::PUBLIC_PATHS.each { |p| puts "  #{p}" }

    puts
    puts 'Guest/logged-out paths:'
    JitWarmupService::GUEST_PATHS.each { |p| puts "  #{p}" }

    puts
    puts 'Utility paths:'
    JitWarmupService::UTILITY_PATHS.each { |p| puts "  #{p}" }

    puts
    puts "Total: #{JitWarmupService.all_warmup_paths.size} paths"
  end

  desc 'Benchmark warmup iterations to find optimal count'
  task benchmark: :environment do
    require 'benchmark'

    puts "Benchmarking JIT warmup iterations..."
    puts "Ruby engine: #{RUBY_ENGINE} #{RUBY_VERSION}"
    puts

    [1, 2, 3, 5, 10].each do |runs|
      # Reset any caching between runs
      GC.start

      result = Benchmark.measure do
        JitWarmupService.warmup(runs: runs, silent: true)
      end

      puts format("  %2d runs: %7.2fms total, %7.2fms/request",
                  runs,
                  result.real * 1000,
                  result.real * 1000 / (JitWarmupService.all_warmup_paths.size * runs))
    end

    puts
    puts 'Recommendation: Use 3-5 runs for production warmup'
  end
end
