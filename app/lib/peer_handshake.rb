class PeerHandshake
  def initialize(info_hash)
    @info_hash = info_hash
  end

  def to_bytes
    [
      "19".ord,
      "BitTorrent protocol",
      *[0]*8, # Reserved bytes
      [@info_hash].pack("H*"), # This will be 20 bytes
      "00112233445566778899", # Peer ID
    ].join("")
  end
end