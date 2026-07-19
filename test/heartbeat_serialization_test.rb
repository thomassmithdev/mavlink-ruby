# frozen_string_literal: true

require_relative "test_helper"

# Verifies MAVLink 2 header bytes for a standard HEARTBEAT (msgid 0, payload len 9).
class HeartbeatSerializationTest < Minitest::Test
  def test_pack_heartbeat_mavlink2_header
    msg = MAVLink::Message.new(
      payload_length: 9,
      sequence: 0,
      system_id: 1,
      component_id: 1,
      message_id: 0
    )

    packed = msg.pack
    bytes = packed.bytes

    assert_equal 10, packed.bytesize
    assert_equal %w[fd 09 00 00 00 01 01 00 00 00], packed.unpack("H2" * 10)

    assert_equal MAVLink::STX_V2, bytes[0] # stx
    assert_equal 9, bytes[1]               # payload_length
    assert_equal 0, bytes[2]               # incompatibility_flags
    assert_equal 0, bytes[3]               # compatibility_flags
    assert_equal 0, bytes[4]               # sequence
    assert_equal 1, bytes[5]               # system_id
    assert_equal 1, bytes[6]               # component_id
    assert_equal [0, 0, 0], bytes[7, 3]     # message_id (little-endian 24-bit)
  end
end
