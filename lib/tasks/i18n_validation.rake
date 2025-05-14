# frozen_string_literal: true

LOCALES_DIR = Rails.root.join("config/locales")

namespace :i18n do
  desc "Validate that all i18n YAML files in config/locales have matching key structures (including plugin YAMLs)"
  task validate_keys: :environment do
    require "yaml"
    require "pathname"

    # Helper to recursively collect all key paths in a hash
    def collect_keys(hash, prefix = [])
      return Set.new([ prefix.join(".") ]) unless hash.is_a?(Hash)

      hash.flat_map { |k, v| collect_keys(v, prefix + [ k.to_s ]) }.to_set
    end

    # Group YAML files by type: rodauth plugin or main
    files = Dir.glob(LOCALES_DIR.join("*.yml"))
    main_files = files.reject { |f| File.basename(f).start_with?("rodauth.") }
    plugin_files = files.select { |f| File.basename(f).start_with?("rodauth.") }

    def validate_group(files, group_name)
      locale_keys = {}
      files.each do |file|
        data = YAML.load_file(file)
        locale = data.keys.first
        locale_keys[locale] ||= {}
        # For rodauth files, keys are under locale -> rodauth
        keys = if group_name == "plugin"
          data[locale]["rodauth"] || {}
        else
          data[locale] || {}
        end
        locale_keys[locale][file] = collect_keys(keys)
      end

      # Use the first locale as the reference
      _, reference_files = locale_keys.first
      reference_keys = reference_files.values.first
      puts "\n=== Validating #{group_name == 'plugin' ? 'plugin (rodauth.*)' : 'main'} YAML files ==="
      locale_keys.each do |locale, files_hash|
        files_hash.each do |file, keys|
          missing = reference_keys - keys
          extra = keys - reference_keys
          next unless missing.any? || extra.any?

          puts "\nLocale: #{locale} (#{File.basename(file)})"
          puts "  Missing keys:" if missing.any?
          missing.each { |k| puts "    - #{k}" }
          puts "  Extra keys:" if extra.any?
          extra.each { |k| puts "    - #{k}" }
        end
      end
      puts "All #{group_name == 'plugin' ? 'plugin' : 'main'} YAML files have matching keys!" if locale_keys.values.all? { |h| h.values.all? { |k| k == reference_keys } }
    end

    validate_group(main_files, "main")
    validate_group(plugin_files, "plugin")
  end
end
