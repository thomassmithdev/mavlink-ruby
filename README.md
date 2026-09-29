# MAVLink Ruby

A compact MAVLink implementation for Ruby. It packs and unpacks MAVLink 1 and MAVLink 2 frames, checks CRC-16/MCRF4XX checksums, and scans a byte stream for the start of a frame.

Requires Ruby 3.2 or newer.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "mavlink"
```

And then execute:

```bash
bundle install
```

Or install it yourself:

```bash
gem install mavlink
```

## Usage

```ruby
require "mavlink"
```

Payloads are raw bytes. This gem frames those bytes. It does not decode dialect fields such as `HEARTBEAT.type`. Pass the message's `CRC_EXTRA` byte into `pack` and `unpack`. `MAVLink::CRC_EXTRA_HEARTBEAT` is `50`.

### Pack and unpack a frame

A frame is a header, a payload, and a checksum. `pack` recomputes the checksum and appends it. `unpack` raises `ArgumentError` when the length or checksum is wrong.

```ruby
payload = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03].pack("C*")

header = MAVLink::Message.new(
  payload_length: payload.bytesize,
  sequence: 0,
  system_id: 1,
  component_id: 1,
  message_id: 0
)

wire = MAVLink::Frame.new(header: header, payload: payload, checksum: 0)
  .pack(crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)

frame = MAVLink::Frame.unpack(wire, crc_extra: MAVLink::CRC_EXTRA_HEARTBEAT)
frame.header.message_id # => 0
frame.payload           # => the 9 payload bytes
frame.checksum          # => 0xA1B1
```

`Frame.new` checks that `payload.bytesize` matches `header.payload_length` and that `checksum` is an integer in `0..0xFFFF`.

### Headers

`MAVLink::Message` is the packet header. MAVLink 2 is the default (`stx` `0xFD`, 10 bytes, 24-bit `message_id`). MAVLink 1 uses `stx: MAVLink::STX_V1` (`0xFE`, 6 bytes, `message_id` in `0..255`).

```ruby
header = MAVLink::Message.new(
  payload_length: 9,
  sequence: 0,
  system_id: 1,
  component_id: 1,
  message_id: 0
)

header.mavlink2?  # => true
header.pack       # => 10-byte binary header
MAVLink::Message.unpack(header.pack) # => header
```

MAVLink 1:

```ruby
header = MAVLink::Message.new(
  stx: MAVLink::STX_V1,
  payload_length: 9,
  sequence: 0,
  system_id: 1,
  component_id: 1,
  message_id: 0
)

header.pack.bytesize # => 6
```

Header fields:

| Field | Range |
| --- | --- |
| `stx` | `STX_V1` (`0xFE`) or `STX_V2` (`0xFD`) |
| `payload_length` | `0..255` |
| `incompatibility_flags` | `0..255` (must be `0` for MAVLink 1) |
| `compatibility_flags` | `0..255` (must be `0` for MAVLink 1) |
| `sequence` | `0..255` |
| `system_id` | `0..255` |
| `component_id` | `0..255` |
| `message_id` | `0..0xFFFFFF` (`0..255` for MAVLink 1) |

`Message.unpack` expects exactly 10 bytes for MAVLink 2 and exactly 6 bytes for MAVLink 1.

### Scan a byte stream

`MAVLink::Parser` reads a continuous stream. It drops bytes until it sees `0xFE` or `0xFD`, then keeps that byte and everything after it. `feed` accepts a binary `String` or one integer in `0..255`, and returns the parser. `<<` is an alias.

```ruby
parser = MAVLink::Parser.new
parser.waiting_for_stx? # => true

parser.feed([0x00, 0x11, MAVLink::STX_V2, 0x09].pack("C*"))
parser.got_stx?  # => true
parser.stx       # => 0xFD
parser.buffer    # => bytes from 0xFD onward
```

`buffer` is a copy. The parser does not yet split that buffer into frames. Once a full frame is buffered, decode it with `MAVLink::Frame.unpack`.

### Checksum

`MAVLink::CRC` is CRC-16/MCRF4XX: init `0xFFFF`, no final XOR. The check vector `"123456789"` is `0x6F91`.

```ruby
MAVLink::CRC.calculate("123456789") # => 0x6F91

crc = MAVLink::CRC::INIT
crc = MAVLink::CRC.accumulate(byte, crc)
```

A frame checksum covers the header without the magic byte, the payload, and one extra `CRC_EXTRA` byte that depends on the message id.

## Development

```bash
bin/setup
bundle exec rake test
```

`bundle exec rake build` writes the package to `pkg/`. `bundle exec rake release` tags the current version and pushes it to RubyGems.

## License

MIT. See [LICENSE](LICENSE).
