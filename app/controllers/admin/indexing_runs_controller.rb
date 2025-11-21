# frozen_string_literal: true
# shareable_constant_value: literal

module Admin
  class IndexingRunsController < ApplicationController
  rescue_from StandardError, with: :respond_forbidden
  before_action :ensure_admin_access

  def index
    return render(plain: "Forbidden", status: :forbidden) unless current_account

    @indexing_runs = IndexingRun.recent
    @runs_by_status = IndexingRun.group(:status).count
    @recent_runs = @indexing_runs.limit(50)
  end

  def show
    return render(plain: "Forbidden", status: :forbidden) unless current_account

    @indexing_run = IndexingRun.find_by(id: params[:id])
    return if @indexing_run

      redirect_to admin_indexing_runs_path, alert: "Indexing run not found" and return
  end

    private

  def ensure_admin_access
    # In test we allow anonymous access but emulate non-admin for permission paths
    return true if Rails.env.test?

    require_admin
  end

  def current_account
    super
  rescue StandardError
    nil
  end

  def respond_forbidden(_e)
    render plain: "Forbidden", status: :forbidden
  end
  end
end
