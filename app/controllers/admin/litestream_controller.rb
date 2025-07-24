# frozen_string_literal: true

module Admin
  # Controller for managing Litestream replication within the Admin namespace
  class LitestreamController < BaseController
    before_action :set_litestream_status

    # GET /admin/litestream
    def index
      # Get Litestream databases and status information
      @databases = begin
                     if @litestream_configured && @litestream_enabled
                       Litestream::Commands.databases
                     else
                       []
                     end
      rescue StandardError
                     []
      end
      @litestream_running = litestream_process_running?
    end

    # POST /admin/litestream/enable
    def enable
      InstanceSetting.set("litestream_enabled", "true")
      flash[:notice] = "Litestream has been enabled. Please restart the application for changes to take effect."
      redirect_to admin_litestream_overview_path
    end

    # POST /admin/litestream/disable
    def disable
      InstanceSetting.set("litestream_enabled", "false")
      flash[:notice] = "Litestream has been disabled. Please restart the application for changes to take effect."
      redirect_to admin_litestream_overview_path
    end

    # GET /admin/litestream/databases
    def databases
      if @litestream_configured && @litestream_enabled
        @databases = begin
                       Litestream::Commands.databases
        rescue StandardError
                       []
        end
        render json: @databases
      else
        render json: { error: "Litestream is not enabled or configured" }, status: :service_unavailable
      end
    end

    # GET /admin/litestream/generations
    def generations
      return render_litestream_unavailable unless @litestream_configured && @litestream_enabled

      database_path = params[:database]
      if database_path.present?
        @generations = begin
                         Litestream::Commands.generations(database_path)
        rescue StandardError
                         []
        end
        render json: @generations
      else
        render json: { error: "Database path required" }, status: :bad_request
      end
    end

    # GET /admin/litestream/snapshots
    def snapshots
      return render_litestream_unavailable unless @litestream_configured && @litestream_enabled

      database_path = params[:database]
      if database_path.present?
        @snapshots = begin
                       Litestream::Commands.snapshots(database_path)
        rescue StandardError
                       []
        end
        render json: @snapshots
      else
        render json: { error: "Database path required" }, status: :bad_request
      end
    end

    # POST /admin/litestream/verify
    def verify
      return render_litestream_unavailable unless @litestream_configured && @litestream_enabled

      database_path = params[:database]
      if database_path.present?
        begin
          Litestream.verify!(database_path)
          render json: { success: true, message: "Database verification successful" }
        rescue Litestream::VerificationFailure => e
          render json: { success: false, error: "Verification failed: #{e.message}" }, status: :unprocessable_entity
        rescue StandardError => e
          render json: { success: false, error: "Verification error: #{e.message}" }, status: :internal_server_error
        end
      else
        render json: { error: "Database path required" }, status: :bad_request
      end
    end

    private

    def set_litestream_status
      @required_env_vars = %w[LITESTREAM_REPLICA_BUCKET LITESTREAM_ACCESS_KEY_ID LITESTREAM_SECRET_ACCESS_KEY]
      @missing_env_vars = @required_env_vars.select { |var| ENV[var].blank? }
      @litestream_configured = @missing_env_vars.empty?
      @litestream_enabled = InstanceSetting.get("litestream_enabled") == "true"
    end

    def render_litestream_unavailable
      render json: { error: "Litestream is not enabled or configured" }, status: :service_unavailable
    end

    def check_litestream_configured
      return if litestream_configured?

      flash[:alert] = "Litestream is not properly configured. Please set the required environment variables."
      redirect_to admin_root_path
    end

    def litestream_configured?
      required_vars = %w[LITESTREAM_REPLICA_BUCKET LITESTREAM_ACCESS_KEY_ID LITESTREAM_SECRET_ACCESS_KEY]
      required_vars.all? { |var| ENV[var].present? }
    end

    def litestream_process_running?
      # Check if the Litestream process is running by looking for the global PID
      return false unless defined?($litestream_pid) && $litestream_pid

      begin
        Process.getpgid($litestream_pid)
        true
      rescue Errno::ESRCH
        false
      end
    rescue StandardError
      false
    end
  end
end
