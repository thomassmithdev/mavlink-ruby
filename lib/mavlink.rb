# frozen_string_literal: true

require_relative "mavlink/version"

module MAVLink
  STX_V1 = 0xFE
  STX_V2 = 0xFD
  CRC_EXTRA_HEARTBEAT = 50
end

require_relative "mavlink/crc"
require_relative "mavlink/message"
require_relative "mavlink/frame"