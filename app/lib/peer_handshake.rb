class PeerHandshake
  attr_accessor :info_hash
  attr_accessor :peer_id

  def initialize(info_hash, peer_id)
    @info_hash = info_hash
    @peer_id = peer_id
  end

  def self.from_bytes(bytes)
    info_hash = bytes[28..47].unpack1('H*')
    peer_id = bytes[48..67].unpack1('H*')
    new(info_hash, peer_id)
  end

  def to_bytes
    [
      19.chr,
      "BitTorrent protocol",
      "\x00" * 8, # Reserved bytes
      [@info_hash].pack("H*"), # This will be 20 bytes
      @peer_id,
    ].join("")
  end

  def to_s
    "<PeerHandshake(info_hash: #{@info_hash}, peer_id: #{@peer_id})>"
  end
end