# Configure zip_kit to use maximum compression for streaming ZIPs
# This overrides the default compression level in ZipKit::Streamer::DeflatedWriter

module ZipKit
  class Streamer
    class DeflatedWriter
      # Override the initialize method to use BEST_COMPRESSION instead of DEFAULT_COMPRESSION
      def initialize(io)
        @compressed_io = io
        # Use maximum compression instead of default
        @deflater = ::Zlib::Deflate.new(Zlib::BEST_COMPRESSION, -::Zlib::MAX_WBITS)
        @crc = ZipKit::StreamCRC32.new
        @crc_buf = ZipKit::WriteBuffer.new(@crc, CRC32_BUFFER_SIZE)
      end
    end
  end
end
