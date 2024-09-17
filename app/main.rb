require "json"
require "stringio"

if ARGV.length < 2
  puts "Usage: your_bittorrent.sh <command> <args>"
  exit 1
end

class BencodeDecoder
  def self.decode(bencoded_value)
    io = StringIO.new(bencoded_value)

    self.do_decode(io)
  end

  def self.do_decode(io)
    char = io.read(1)

    case char
    when "i"
      self.decode_integer(io)
    when "d"
      self.decode_dictionary(io)
    when "l"
      self.decode_list(io)
    when "1".."9"
      self.decode_string(io, char)
    else
      raise "unexpected character #{char}"
    end
  end

  def self.decode_integer(io)
    integer_str = ""

    while
      char = io.read(1)
      break if char == "e"
      integer_str += char
    end

    integer_str.to_i
  end

  def self.decode_string(io, first_char)
    length_str = first_char

    while
      char = io.read(1)
      break if char == ":"
      length_str += char
    end

    length = length_str.to_i
    io.read(length)
  end

  def self.decode_dictionary(io)
    raise NotImplementedError
  end

  def self.decode_list(io)
    raise NotImplementedError
  end
end

command = ARGV[0]

if command == "decode"
  decoded = BencodeDecoder.decode(ARGV[1])
  puts JSON.generate(decoded)
else
  raise "unsupported command #{command}"
end
