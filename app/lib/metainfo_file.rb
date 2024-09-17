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

  def tracker_url
    @raw_dict.fetch("announce")
  end

  def length
    info_dict.fetch("length")
  end
end