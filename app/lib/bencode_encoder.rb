class BencodeEncoder
  def self.encode(value)
    case value
    when Integer
      encode_integer(value)
    when String
      encode_string(value)
    when Hash
      encode_dictionary(value)
    when Array
      encode_list(value)
    else
      raise "Unsupported type: #{value.class}"
    end
  end

  private

  def self.encode_integer(integer)
    "i#{integer}e"
  end

  def self.encode_string(string)
    "#{string.bytesize}:#{string}"
  end

  def self.encode_dictionary(dictionary)
    encoded = dictionary.sort_by { |key, _| key }.map { |key, value| encode(key) + encode(value) }
    "d#{encoded.join}e"
  end

  def self.encode_list(list)
    encoded = list.map { |item| encode(item) }
    "l#{encoded.join}e"
  end
end