require "digest"

class MetainfoFile
  def self.parse(bencoded_value)
    decoded = BencodeDecoder.decode(bencoded_value)
    new(decoded)
  end

  def initialize(raw_dict)
    @raw_dict = raw_dict
  end

  def info_dict
    @raw_dict.fetch("info")
  end

  def info_hash
    Digest::SHA1.hexdigest(BencodeEncoder.encode(info_dict))
  end

  def piece_length
    info_dict.fetch("piece length")
  end

  def pieces
    info_dict.fetch("pieces").each_char.each_slice(20).each_with_index.map do |hash_chars, index|
      is_last_piece = index == info_dict.fetch("pieces").length / 20 - 1
      Piece.new(index, is_last_piece ? (length - (index * piece_length)) : piece_length, hash_chars.join.unpack1("H*"))
    end
  end

  def tracker_url
    @raw_dict.fetch("announce")
  end

  def length
    info_dict.fetch("length")
  end
end
