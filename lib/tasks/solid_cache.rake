# frozen_string_literal: true

namespace :solid_cache do
  desc "Sample Solid Cache entry sizes (compressed vs raw). ENV: LIMIT=100 LIKE='prefix%' SHOW=1"
  task sample_sizes: :environment do
    limit = (ENV['LIMIT'] || '100').to_i
    like  = ENV['LIKE']
    show  = ENV.fetch('SHOW', '0') !~ /^(0|false|no)$/i

    unless defined?(SolidCache)
      puts 'SolidCache not loaded.'
      next
    end

  # We'll compute raw size by attempting Snappy.inflate only (no Marshal.load),
  # so we don't need application classes loaded to decode.

    scope = SolidCache::Entry.all
    scope = scope.where('key LIKE ?', like) if like.present?
    # Random sampling for SQLite; adjust if needed for other DBs
    scope = scope.order(Arel.sql('RANDOM()'))
    scope = scope.limit(limit) if limit > 0

    rows = []
    compressed_total = 0
    raw_total = 0

    scope.each do |entry|
      payload = entry.value
      compressed_size = payload ? payload.bytesize : 0
      # Try to decompress; if not compressed, treat payload as raw
      raw_bytes = if payload
                    if defined?(Snappy)
                      begin
                        Snappy.inflate(payload)
                      rescue StandardError
                        payload
                      end
                    else
                      payload
                    end
                  else
                    ''.b
                  end
      raw_size = raw_bytes.bytesize

      compressed_total += compressed_size
      raw_total += raw_size
      rows << [entry.key, compressed_size, raw_size]
    end

    count = rows.size
    puts "Sampled #{count} entries"
    if count > 0
      avg_c = compressed_total.to_f / count
      avg_r = raw_total.to_f / count
      ratio = avg_r > 0 ? (avg_c / avg_r) : 0.0
      puts format('Avg compressed: %.1f bytes', avg_c)
      puts format('Avg raw:        %.1f bytes', avg_r)
      puts format('Compression ratio (compressed/raw): %.3f', ratio)

      if show
        puts '\nTop 10 by raw size:'
        rows.sort_by { |_, _, r| -r }.first(10).each do |key, c, r|
          rr = r > 0 ? (c.to_f / r) : 0.0
          puts format('- %-60s raw:%8dB  comp:%8dB  ratio: %.3f', key, r, c, rr)
        end
      end
    end
  end
end
