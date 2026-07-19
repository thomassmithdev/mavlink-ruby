# frozen_string_literal: true

module MAVLink
  # Immutable MAVLink packet header (v1 or v2 framing)
  Message = ::Data.define(
    :stx,
    :payload_length,
    :incompatibility_flags,
    :compatibility_flags,
    :sequence,
    :system_id,
    :component_id,
    :message_id
  ) do
    def initialize(
      stx: STX_V2,
      payload_length:,
      incompatibility_flags: 0,
      compatibility_flags: 0,
      sequence:,
      system_id:,
      component_id:,
      message_id:
    )
      validate_stx!(stx)
      validate_uint8!(:payload_length, payload_length)
      validate_uint8!(:incompatibility_flags, incompatibility_flags)
      validate_uint8!(:compatibility_flags, compatibility_flags)
      validate_uint8!(:sequence, sequence)
      validate_uint8!(:system_id, system_id)
      validate_uint8!(:component_id, component_id)
      validate_message_id!(message_id)
      validate_v1_constraints!(stx, incompatibility_flags, compatibility_flags, message_id)

      super(
        stx: stx,
        payload_length: payload_length,
        incompatibility_flags: incompatibility_flags,
        compatibility_flags: compatibility_flags,
        sequence: sequence,
        system_id: system_id,
        component_id: component_id,
        message_id: message_id
      )
    end

    def mavlink2?
      stx == STX_V2
    end

    def mavlink1?
      stx == STX_V1
    end

    def pack
      if mavlink2?
        [
          stx, payload_length, incompatibility_flags, compatibility_flags,
          sequence, system_id, component_id, message_id & 0xFF,
          (message_id >> 8) & 0xFF, (message_id >> 16) & 0xFF
        ].pack("C*")
      else
        [stx, payload_length, sequence, system_id, component_id, message_id].pack("C*")
      end
    end

    private

    def validate_stx!(stx)
      return if stx == STX_V1 || stx == STX_V2

      raise ArgumentError, "stx must be STX_V1 (0xFE) or STX_V2 (0xFD), got #{stx.inspect}"
    end

    def validate_uint8!(name, value)
      return if value.is_a?(Integer) && value.between?(0, 255)

      raise ArgumentError, "#{name} must be an integer in 0..255, got #{value.inspect}"
    end

    def validate_message_id!(message_id)
      return if message_id.is_a?(Integer) && message_id.between?(0, 0xFFFFFF)

      raise ArgumentError, "message_id must be an integer in 0..0xFFFFFF, got #{message_id.inspect}"
    end

    def validate_v1_constraints!(stx, incompatibility_flags, compatibility_flags, message_id)
      return unless stx == STX_V1

      if incompatibility_flags != 0 || compatibility_flags != 0
        raise ArgumentError, "MAVLink 1 headers must have zero incompatibility_flags and compatibility_flags"
      end

      return if message_id <= 255

      raise ArgumentError, "MAVLink 1 message_id must be in 0..255, got #{message_id.inspect}"
    end
  end
end
