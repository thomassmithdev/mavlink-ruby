# frozen_string_literal: true

require_relative "test_helper"

# Raw-byte integrity checks for full MAVLink frames (header + payload + checksum)
class FrameIntegrityTest < Minitest::Test
  # MAVLink 2 HEARTBEAT: header from existing tests + 9-byte payload (mavlink_version=3)
  # Checksum includes CRC_EXTRA_HEARTBEAT (50)
  HEARTBEAT_V2 = [
    0xFD, 0x09, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03,
    0xB1, 0xA1
  ].pack("C*")

  HEARTBEAT_PAYLOAD = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03].pack("C*")
  EXPECTED_CHECKSUM = 0xA1B1

  def test_unpack_identifies_heartbeat_message_type
    frame = MAVLink::Frame.unpack(HEARTBEAT_V2, crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)

    assert_equal 0, frame.header.message_id
    assert_equal 9, frame.header.payload_length
    assert_equal MAVLink::STX_V2, frame.header.stx
    assert_equal HEARTBEAT_PAYLOAD, frame.payload
  end

  def test_unpack_calculates_checksum_properly
    frame = MAVLink::Frame.unpack(HEARTBEAT_V2, crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)

    assert_equal EXPECTED_CHECKSUM, frame.checksum
  end

  def test_unpack_rejects_corrupted_payload
    corrupted = HEARTBEAT_V2.dup
    corrupted.setbyte(10, corrupted.getbyte(10) ^ 0xFF)

    assert_raises(ArgumentError) do
      MAVLink::Frame.unpack(corrupted, crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)
    end
  end

  def test_unpack_rejects_corrupted_checksum
    corrupted = HEARTBEAT_V2.dup
    corrupted.setbyte(-1, corrupted.getbyte(-1) ^ 0xFF)

    assert_raises(ArgumentError) do
      MAVLink::Frame.unpack(corrupted, crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)
    end
  end

  def test_unpack_rejects_truncated_frame
    assert_raises(ArgumentError) do
      MAVLink::Frame.unpack(HEARTBEAT_V2.byteslice(0, -1), crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)
    end
  end

  def test_unpack_rejects_wrong_length
    too_long = HEARTBEAT_V2 + "\x00"

    assert_raises(ArgumentError) do
      MAVLink::Frame.unpack(too_long, crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)
    end
  end

  def test_pack_unpack_round_trip
    header = MAVLink::Message.new(
      payload_length: 9,
      sequence: 0,
      system_id: 1,
      component_id: 1,
      message_id: 0
    )
    frame = MAVLink::Frame.new(
      header: header,
      payload: HEARTBEAT_PAYLOAD,
      checksum: EXPECTED_CHECKSUM
    )

    packed = frame.pack(crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)
    assert_equal HEARTBEAT_V2, packed

    unpacked = MAVLink::Frame.unpack(packed, crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)
    assert_equal frame, unpacked
  end
end
