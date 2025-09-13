# frozen_string_literal: true

module GoogleRobotstxtParser
end

# Ensure the extension directory is on the load path when loading from a vendored path
ext_dir = File.expand_path('../../ext/robotstxt', __FILE__)
$LOAD_PATH.unshift(ext_dir) unless $LOAD_PATH.include?(ext_dir)

# Load native extension providing the Robotstxt module; if missing, try to build it
begin
	require 'robotstxt'
rescue LoadError => e
	begin
		require 'mkmf'
		Dir.chdir(ext_dir) do
			# Generate Makefile and build the extension
			system(RbConfig.ruby, 'extconf.rb') || raise('extconf.rb failed')
			system(ENV['MAKE'] || 'make') || raise('make failed')
		end
		# Retry loading
		require 'robotstxt'
	rescue StandardError => build_err
		raise LoadError, "google_robotstxt_parser: failed to load native extension 'robotstxt'.\nOriginal: #{e.message}\nBuild error: #{build_err.message}\nEnsure 'cmake' and 'git' are installed (e.g., 'brew install cmake git' on macOS)."
	end
end
