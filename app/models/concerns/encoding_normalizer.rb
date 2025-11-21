# frozen_string_literal: true
# shareable_constant_value: literal

module EncodingNormalizer
  extend ActiveSupport::Concern

  class_methods do
    # Normalize encoding of specified string attributes before validation
    def normalize_encoding_for(*attrs)
      before_validation do
        attrs.each do |attr|
          val = send(attr)
          next unless val.is_a?(String)

          unless val.encoding == Encoding::UTF_8
            begin
              val = val.dup.force_encoding(Encoding::UTF_8)
            rescue StandardError
              # fallback attempt
            end
          end
          val = val.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "") unless val.valid_encoding?
          send("#{attr}=", val)
        end
      end
    end
  end
end
