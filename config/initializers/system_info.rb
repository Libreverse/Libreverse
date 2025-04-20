# frozen_string_literal: true

require "etc"

Rails.logger.info "[Boot] Detected #{Etc.nprocessors} CPU cores (Etc.nprocessors)"
