class BencodeDecoder
  def self.decode(bencoded_value)
    io = StringIO.new(bencoded_value.dup)

    do_decode(io)
  end

  def self.do_decode(io)
    char = io.read(1)

    case char
    when "i"
      decode_integer(io)
    when "d"
      decode_dictionary(io)
    when "l"
      decode_list(io)
    when "1".."9"
      io.ungetc(char)
      decode_string(io)
    else
      raise "unexpected character #{char}"
    end
  end

  def self.decode_integer(io)
    integer_str = ""

    while (char = io.read(1)) != "e"
      integer_str += char
    end

    integer_str.to_i
  end

  def self.decode_string(io)
    length_str = ""

    while (char = io.read(1)) != ":"
      length_str += char
    end

    length = length_str.to_i
    io.read(length)
  end

  def self.decode_dictionary(io)
    dictionary = {}

    while (char = io.read(1)) != "e"
      io.ungetc(char)
      key = do_decode(io)
      value = do_decode(io)
      dictionary[key] = value
    end

    dictionary
  end

  def self.decode_list(io)
    elements = []

    while (char = io.read(1)) != "e"
      io.ungetc(char)
      elements << do_decode(io)
    end

    elements
  end
end
