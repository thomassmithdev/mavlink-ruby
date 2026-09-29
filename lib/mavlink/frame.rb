# frozen_string_literal: true

module MAVLink
  # Full MAVLink packet: header + payload + CRC-16 checksum
  Frame = ::Data.define(:header, :payload, :checksum) do
    HEADER_LEN_V1 = 6
    HEADER_LEN_V2 = 10
    CHECKSUM_LEN = 2

    def initialize(header:, payload:, checksum:)
      raise ArgumentError, "header must be a MAVLink::Message, got #{header.class}" unless header.is_a?(Message)
      raise ArgumentError, "payload must be a String, got #{payload.class}" unless payload.is_a?(String)
      unless payload.bytesize == header.payload_length
        raise ArgumentError,
              "payload length #{payload.bytesize} does not match header.payload_length #{header.payload_length}"
      end
      unless checksum.is_a?(Integer) && checksum.between?(0, 0xFFFF)
        raise ArgumentError, "checksum must be an integer in 0..0xFFFF, got #{checksum.inspect}"
      end

      super(header: header, payload: payload.b, checksum: checksum)
    end

    def pack(crc_extra:)
      header_bytes = header.pack
      ck = self.class.compute_checksum(header_bytes, payload, crc_extra)
      header_bytes + payload + [ck & 0xFF, (ck >> 8) & 0xFF].pack("C*")
    end

    def self.unpack(binary, crc_extra:)
      raise ArgumentError, "binary must be a String, got #{binary.class}" unless binary.is_a?(String)
      raise ArgumentError, "binary is empty" if binary.empty?

      stx = binary.getbyte(0)
      header_len = header_length_for(stx)
      raise ArgumentError, "frame too short for header, got #{binary.bytesize} bytes" if binary.bytesize < header_len

      payload_length = binary.getbyte(1)
      expected = header_len + payload_length + CHECKSUM_LEN
      unless binary.bytesize == expected
        raise ArgumentError, "frame requires #{expected} bytes, got #{binary.bytesize}"
      end

      header = Message.unpack(binary.byteslice(0, header_len))
      payload = binary.byteslice(header_len, payload_length).b
      checksum = binary.getbyte(header_len + payload_length) |
                 (binary.getbyte(header_len + payload_length + 1) << 8)

      expected_checksum = compute_checksum(binary.byteslice(0, header_len), payload, crc_extra)
      unless checksum == expected_checksum
        raise ArgumentError,
              "checksum mismatch: got 0x#{checksum.to_s(16)}, expected 0x#{expected_checksum.to_s(16)}"
      end

      new(header: header, payload: payload, checksum: checksum)
    end

    def self.compute_checksum(header_bytes, payload, crc_extra)
      crc = CRC.calculate(header_bytes.byteslice(1, header_bytes.bytesize - 1) + payload)
      CRC.accumulate(crc_extra, crc)
    end

    def self.header_length_for(stx)
      case stx
      when STX_V2 then HEADER_LEN_V2
      when STX_V1 then HEADER_LEN_V1
      else
        raise ArgumentError, "stx must be STX_V1 (0xFE) or STX_V2 (0xFD), got #{stx.inspect}"
      end
    end
    private_class_method :header_length_for
  end
end
