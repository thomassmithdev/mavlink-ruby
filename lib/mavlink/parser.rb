# frozen_string_literal: true

module MAVLink
  # Incremental state machine for a continuous MAVLink byte stream.
  #
  # Starts in WAITING_FOR_STX and discards bytes until a start-of-frame
  # marker arrives: STX_V1 (0xFE) or STX_V2 (0xFD). That byte is kept and
  # the machine moves to GOT_STX. Later bytes are retained and not treated
  # as a new search.
  class Parser
    WAITING_FOR_STX = :waiting_for_stx
    GOT_STX = :got_stx

    attr_reader :state, :stx

    def initialize
      @state = WAITING_FOR_STX
      @stx = nil
      @buffer = String.new(encoding: Encoding::BINARY)
    end

    def waiting_for_stx?
      state == WAITING_FOR_STX
    end

    def got_stx?
      state == GOT_STX
    end

    # Bytes kept from the start-of-frame onward. Empty while still scanning.
    def buffer
      @buffer.dup
    end

    # Consume a String of bytes, or a single Integer byte in 0..255.
    # Returns self so chunks can be chained.
    def feed(data)
      each_input_byte(data) { |byte| accept(byte) }
      self
    end
    alias << feed

    private

    def accept(byte)
      case state
      when WAITING_FOR_STX
        return unless start_of_frame?(byte)

        @stx = byte
        @buffer << byte
        @state = GOT_STX
      when GOT_STX
        @buffer << byte
      end
    end

    def start_of_frame?(byte)
      byte == STX_V1 || byte == STX_V2
    end

    def each_input_byte(data)
      case data
      when String
        data.each_byte { |byte| yield byte }
      when Integer
        unless data.between?(0, 255)
          raise ArgumentError, "byte must be an integer in 0..255, got #{data}"
        end

        yield data
      else
        raise ArgumentError, "data must be a String or Integer byte, got #{data.class}"
      end
    end
  end
end
