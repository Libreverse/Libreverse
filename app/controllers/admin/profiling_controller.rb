# frozen_string_literal: true
# shareable_constant_value: literal

module Admin
    class ProfilingController < BaseController
        # POST /admin/profiling/enable
        def enable
            ttl = fetch_ttl
            session[:profiling] = {
              enabled: true,
              enabled_by: current_account&.id,
              started_at: Time.now.to_i,
              expires_at: (Time.zone.now + ttl.minutes).to_i
            }

            flash[:notice] = "Profiling enabled for #{ttl} minute(s)."
            redirect_back fallback_location: admin_root_path
        end

        # POST /admin/profiling/disable
        def disable
            # For admins (default-on), set a short-lived force_disabled flag to turn it off.
            ttl = fetch_ttl
            session[:profiling] = {
              force_disabled: true,
              disabled_by: current_account&.id,
              started_at: Time.now.to_i,
              expires_at: (Time.zone.now + ttl.minutes).to_i
            }

            flash[:notice] = "Profiling disabled for #{ttl} minute(s)."
            redirect_back fallback_location: admin_root_path
        end

        # POST /admin/profiling/force_disable
        def force_disable
            ttl = fetch_ttl
            session[:profiling] = {
              force_disabled: true,
              disabled_by: current_account&.id,
              started_at: Time.now.to_i,
              expires_at: (Time.zone.now + ttl.minutes).to_i
            }
            flash[:notice] = "Profiling force-disabled for #{ttl} minute(s)."
            redirect_back fallback_location: admin_root_path
        end

      private

        def fetch_ttl
            params.fetch(:ttl) { 15 }.to_i.clamp(1, 60) # minutes
        end
    end
end
