# frozen_string_literal: true

module MAVLink
  # CRC-16/MCRF4XX (MAVLink checksum)
  # Init 0xFFFF, no final XOR.
  module CRC
    INIT = 0xFFFF

    def self.accumulate(byte, crc)
      tmp = (byte ^ (crc & 0xFF)) & 0xFF
      tmp = (tmp ^ (tmp << 4)) & 0xFF
      ((crc >> 8) ^ (tmp << 8) ^ (tmp << 3) ^ (tmp >> 4)) & 0xFFFF
    end

    def self.calculate(data)
      crc = INIT
      data.each_byte { |byte| crc = accumulate(byte, crc) }
      crc
    end
  end
end
