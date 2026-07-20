# frozen_string_literal: true

require_relative "test_helper"

class CRCTest < Minitest::Test
  def test_calculate_check_vector
    assert_equal 0x6F91, MAVLink::CRC.calculate("123456789")
  end

  def test_calculate_empty_returns_init
    assert_equal MAVLink::CRC::INIT, MAVLink::CRC.calculate("")
  end

  def test_accumulate_matches_calculate
    data = "123456789"
    crc = MAVLink::CRC::INIT
    data.each_byte { |byte| crc = MAVLink::CRC.accumulate(byte, crc) }

    assert_equal MAVLink::CRC.calculate(data), crc
  end
end
