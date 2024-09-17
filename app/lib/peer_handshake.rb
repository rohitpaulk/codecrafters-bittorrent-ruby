class PeerHandshake
  attr_accessor :info_hash
  attr_accessor :peer_id

  def initialize(info_hash, peer_id, supports_extension_protocol: false)
    @info_hash = info_hash
    @peer_id = peer_id
    @supports_extension_protocol = supports_extension_protocol
  end

  def self.from_bytes(bytes)
    info_hash = bytes[28..47].unpack1("H*")
    peer_id = bytes[48..67].unpack1("H*")
    supports_extension_protocol = (bytes[25].ord & (1 << 4)) != 0
    new(info_hash, peer_id, supports_extension_protocol: supports_extension_protocol)
  end

  def supports_extension_protocol?
    @supports_extension_protocol
  end

  def to_bytes
    [
      19.chr,
      "BitTorrent protocol",
      @supports_extension_protocol ? "\x00\x00\x00\x00\x00\x10\x00\x00" : "\x00" * 8, # Reserved bytes
      [@info_hash].pack("H*"), # This will be 20 bytes
      @peer_id
    ].join("")
  end

  def to_s
    "<PeerHandshake(info_hash: #{@info_hash}, peer_id: #{@peer_id})>"
  end
end
