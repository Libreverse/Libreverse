# frozen_string_literal: true

module Admin
  class IndexingRunsController < ApplicationController
  before_action :ensure_admin_access

  def index
    @indexing_runs = IndexingRun.recent.includes
    @runs_by_status = IndexingRun.group(:status).count
    @recent_runs = @indexing_runs.limit(50)
  end

  def show
    @indexing_run = IndexingRun.find(params[:id])
  end

    private

  def ensure_admin_access
    # Add your admin authentication logic here
    true
  end
  end
end
