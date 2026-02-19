# frozen_string_literal: true
# shareable_constant_value: literal

require "set"

namespace :routes do
  desc "Generate a route surface report including sitemap inclusion hints"
  task surface_report: :environment do
    controller = SitemapController.new
    sitemap_paths = controller.send(:discoverable_paths).to_set

    rails_rows = Rails.application.routes.routes.filter_map do |route|
      path = route.path.spec.to_s.sub("(.:format)", "")
      next if path.blank?

      raw_verb = route.verb.respond_to?(:source) ? route.verb.source : route.verb.to_s
      verb = raw_verb.to_s.gsub(/[\^$]/, "")
      helper = route.name.to_s
      reqs = route.defaults
      target = [reqs[:controller], reqs[:action]].compact.join("#")
      target = "(rack endpoint)" if target.blank?

      [verb.presence || "ALL", path, helper.presence || "-", target, sitemap_paths.include?(path)]
    end

    rails_rows.sort_by! { |row| [row[1], row[0], row[2]] }

    puts "Route surface report"
    puts "Generated at: #{Time.current.iso8601}"
    puts
    puts "%-12s %-50s %-35s %-35s %s" % ["VERB", "PATH", "HELPER", "TARGET", "IN_SITEMAP"]
    puts "-" * 150

    rails_rows.each do |verb, path, helper, target, in_sitemap|
      puts "%-12s %-50s %-35s %-35s %s" % [verb, path, helper, target, in_sitemap ? "yes" : "no"]
    end

    puts
    puts "Total routes: #{rails_rows.size}"
    puts "Sitemap-discoverable static routes: #{sitemap_paths.size}"
    puts "Hint: run `rails rodauth:routes` for the RodauthApp-specific route table."
  end
end
