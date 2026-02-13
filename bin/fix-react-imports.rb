#!/usr/bin/env ruby

# Script to add React import to all icon components in ror_components

require 'find'

Dir.chdir('/Users/george/Libreverse') do
  Find.find('app/javascript/src/iconsV2/ror_components') do |path|
    next unless path.end_with?('.tsx')

    content = File.read(path)
    if content.match?(/^import \{.*\} from "react";/)
      new_content = content.sub(/^import \{(.+)\} from "react";/, 'import React, {\1} from "react";')
      File.write(path, new_content)
      puts "Updated #{path}"
    end
  end
end

puts "All icon components updated."
