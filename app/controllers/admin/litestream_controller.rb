# frozen_string_literal: true

module Admin
  # Controller for managing Litestream replication within the Admin namespace
  class LitestreamController < BaseController
    before_action :check_litestream_configured

    # GET /admin/litestream
    def index
      # Get Litestream databases and status information
      @databases = begin
                     Litestream::Commands.databases
      rescue StandardError
                     []
      end
      @litestream_configured = litestream_configured?
      @required_env_vars = %w[LITESTREAM_REPLICA_BUCKET LITESTREAM_ACCESS_KEY_ID LITESTREAM_SECRET_ACCESS_KEY]
      @missing_env_vars = @required_env_vars.select { |var| ENV[var].blank? }
      @litestream_running = litestream_process_running?
    end

    # GET /admin/litestream/databases
    def databases
      @databases = begin
                     Litestream::Commands.databases
      rescue StandardError
                     []
      end
      render json: @databases
    end

    # GET /admin/litestream/generations
    def generations
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
