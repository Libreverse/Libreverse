# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'google_robotstxt_parser/version'

Gem::Specification.new do |s|
  s.name        = 'google_robotstxt_parser'
  s.version     = GoogleRobotstxtParser::VERSION
  s.summary     = 'Ruby gem wrapper around Google Robotstxt Parser library'
  s.description = 'Unofficial Ruby wrapper around Google Robotstxt Parser C++ library'
  s.authors     = ['Bastien Montois']
  s.email       = 'contact@la-revanche-des-sites.fr'
  s.files       = Dir['lib/**/*.rb', 'ext/**/*.{rb,cc,h,cpp,c,hpp}', 'ext/**/CMakeLists.txt']
  s.homepage    = 'https://github.com/larevanchedessites/google-robotstxt-ruby'
  s.license     = 'MIT'

  s.require_paths = %w[lib ext]
  s.extensions = ['ext/robotstxt/extconf.rb']
end
