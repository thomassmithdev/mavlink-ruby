# frozen_string_literal: true

require_relative "test_helper"

class ParserTest < Minitest::Test
  def test_starts_waiting_for_start_of_frame
    parser = MAVLink::Parser.new

    assert_predicate parser, :waiting_for_stx?
    assert_nil parser.stx
    assert_equal "".b, parser.buffer
  end

  def test_discards_bytes_until_mavlink2_start_of_frame
    parser = MAVLink::Parser.new
    parser.feed([0x00, 0x11, 0xFF, MAVLink::STX_V2, 0x09].pack("C*"))

    assert_predicate parser, :got_stx?
    assert_equal MAVLink::STX_V2, parser.stx
    assert_equal [MAVLink::STX_V2, 0x09].pack("C*"), parser.buffer
  end

  def test_discards_bytes_until_mavlink1_start_of_frame
    parser = MAVLink::Parser.new
    parser.feed([0x00, MAVLink::STX_V1, 0x09].pack("C*"))

    assert_predicate parser, :got_stx?
    assert_equal MAVLink::STX_V1, parser.stx
    assert_equal [MAVLink::STX_V1, 0x09].pack("C*"), parser.buffer
  end

  def test_scans_across_chunk_boundaries
    parser = MAVLink::Parser.new
    parser.feed([0x01, 0x02].pack("C*"))

    assert_predicate parser, :waiting_for_stx?

    parser << 0x03
    parser << MAVLink::STX_V2

    assert_predicate parser, :got_stx?
    assert_equal MAVLink::STX_V2, parser.stx
    assert_equal [MAVLink::STX_V2].pack("C*"), parser.buffer
  end

  def test_keeps_the_first_start_of_frame
    parser = MAVLink::Parser.new
    parser.feed([MAVLink::STX_V2, 0x00, MAVLink::STX_V1].pack("C*"))

    assert_equal MAVLink::STX_V2, parser.stx
    assert_equal [MAVLink::STX_V2, 0x00, MAVLink::STX_V1].pack("C*"), parser.buffer
  end

  def test_empty_feed_stays_waiting
    parser = MAVLink::Parser.new
    parser.feed("".b)

    assert_predicate parser, :waiting_for_stx?
    assert_nil parser.stx
  end

  def test_feed_rejects_a_byte_outside_uint8
    parser = MAVLink::Parser.new

    assert_raises(ArgumentError) { parser.feed(256) }
    assert_predicate parser, :waiting_for_stx?
  end

  def test_feed_rejects_non_byte_input
    assert_raises(ArgumentError) { MAVLink::Parser.new.feed(nil) }
  end
end
