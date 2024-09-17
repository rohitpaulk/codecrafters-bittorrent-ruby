class BencodeDecoder
  def self.decode(bencoded_value)
    io = StringIO.new(bencoded_value.dup)

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
      io.ungetc(char)
      self.decode_string(io)
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

  def self.decode_string(io)
    length_str = ""

    while
      char = io.read(1)
      break if char == ":"
      length_str += char
    end

    length = length_str.to_i
    io.read(length)
  end

  def self.decode_dictionary(io)
    dictionary = {}

    while
      char = io.read(1)
      break if char == "e"
      io.ungetc(char)
      key = self.do_decode(io)
      value = self.do_decode(io)
      dictionary[key] = value
    end

    dictionary
  end

  def self.decode_list(io)
    elements = []

    while
      char = io.read(1)

      case char
      when "e"
        break
      else
        io.ungetc(char)
        elements << self.do_decode(io)
      end
    end

    elements
  end
end