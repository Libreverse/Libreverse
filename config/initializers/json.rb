# frozen_string_literal: true
# shareable_constant_value: literal

# This replaces the default Rails JSON encoder/decoder with the Oj gem for improved performance.
Oj.optimize_rails
