# frozen_string_literal: true

require_relative "test_helper"

class MessagePackTest < Minitest::Test
  def test_pack_mavlink2_header
    msg = MAVLink::Message.new(
      payload_length: 9,
      sequence: 0,
      system_id: 1,
      component_id: 1,
      message_id: 0
    )

    assert_equal 10, msg.pack.bytesize
    assert_equal %w[fd 09 00 00 00 01 01 00 00 00], msg.pack.unpack("H2" * 10)
  end

  def test_pack_mavlink1_header
    msg = MAVLink::Message.new(
      stx: MAVLink::STX_V1,
      payload_length: 9,
      sequence: 0,
      system_id: 1,
      component_id: 1,
      message_id: 0
    )

    assert_equal 6, msg.pack.bytesize
    assert_equal %w[fe 09 00 01 01 00], msg.pack.unpack("H2" * 6)
  end
end
