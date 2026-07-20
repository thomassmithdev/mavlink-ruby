# frozen_string_literal: true

require_relative "mavlink/version"

module MAVLink
  STX_V1 = 0xFE
  STX_V2 = 0xFD
end

require_relative "mavlink/crc"
require_relative "mavlink/message"