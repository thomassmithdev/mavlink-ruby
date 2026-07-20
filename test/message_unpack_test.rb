# frozen_string_literal: true

require_relative "test_helper"

class MessageUnpackTest < Minitest::Test
  def test_unpack_round_trip_mavlink2
    msg = MAVLink::Message.new(
      payload_length: 9,
      sequence: 0,
      system_id: 1,
      component_id: 1,
      message_id: 0
    )

    assert_equal msg, MAVLink::Message.unpack(msg.pack)
  end

  def test_unpack_round_trip_mavlink1
    msg = MAVLink::Message.new(
      stx: MAVLink::STX_V1,
      payload_length: 9,
      sequence: 0,
      system_id: 1,
      component_id: 1,
      message_id: 0
    )

    assert_equal msg, MAVLink::Message.unpack(msg.pack)
  end

  def test_unpack_known_mavlink2_heartbeat_header
    binary = [0xFD, 0x09, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00].pack("C*")
    msg = MAVLink::Message.unpack(binary)

    assert_equal MAVLink::STX_V2, msg.stx
    assert_equal 9, msg.payload_length
    assert_equal 0, msg.incompatibility_flags
    assert_equal 0, msg.compatibility_flags
    assert_equal 0, msg.sequence
    assert_equal 1, msg.system_id
    assert_equal 1, msg.component_id
    assert_equal 0, msg.message_id
  end

  def test_unpack_mavlink2_multibyte_message_id
    binary = [0xFD, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x03, 0x02, 0x01].pack("C*")
    msg = MAVLink::Message.unpack(binary)

    assert_equal 0x010203, msg.message_id
  end

  def test_unpack_rejects_non_string
    assert_raises(ArgumentError) { MAVLink::Message.unpack(nil) }
    assert_raises(ArgumentError) { MAVLink::Message.unpack([]) }
  end

  def test_unpack_rejects_empty
    assert_raises(ArgumentError) { MAVLink::Message.unpack("") }
  end

  def test_unpack_rejects_invalid_stx
    assert_raises(ArgumentError) { MAVLink::Message.unpack("\x00") }
  end

  def test_unpack_rejects_truncated_mavlink2
    binary = [0xFD, 0x09, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00].pack("C*")
    assert_raises(ArgumentError) { MAVLink::Message.unpack(binary) }
  end

  def test_unpack_rejects_truncated_mavlink1
    binary = [0xFE, 0x09, 0x00, 0x01, 0x01].pack("C*")
    assert_raises(ArgumentError) { MAVLink::Message.unpack(binary) }
  end

  def test_unpack_rejects_too_long_mavlink2
    binary = [0xFD, 0x09, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00].pack("C*")
    assert_raises(ArgumentError) { MAVLink::Message.unpack(binary) }
  end

  def test_unpack_rejects_too_long_mavlink1
    binary = [0xFE, 0x09, 0x00, 0x01, 0x01, 0x00, 0x00].pack("C*")
    assert_raises(ArgumentError) { MAVLink::Message.unpack(binary) }
  end
end
