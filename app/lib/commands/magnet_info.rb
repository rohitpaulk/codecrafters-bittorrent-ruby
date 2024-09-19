class Commands::MagnetInfo
  def self.run(argv)
    magnet_link = MagnetLink.new(argv[1])
    peer_addresses = TrackerClient.new.get_peer_addresses(magnet_link.tracker_urls.first, magnet_link.info_hash)
    peer_connection = PeerConnection.new(magnet_link.info_hash, peer_addresses.first)
    handshake = peer_connection.perform_handshake!
    peer_connection.wait_for_bitfield!
    puts "Peer ID: #{handshake.peer_id}"

    unless handshake.supports_extension_protocol?
      puts "Peer does not support extension protocol"
      exit 1
    end

    handshake = peer_connection.perform_extension_handshake!
    metadata_extension_id = BencodeDecoder.decode(handshake.payload).fetch("m").fetch("ut_metadata")
    puts "Peer Metadata Extension ID: #{metadata_extension_id}"

    peer_connection.send_message!(PeerExtensionMessage.new(metadata_extension_id, BencodeEncoder.encode({"msg_type" => 0, "piece" => 0})))
    message = peer_connection.wait_for_extension_message!

    raise "expected extension message type 6" unless message.extension_id.eql?(6)

    decoded, remaining = BencodeDecoder.decode_partial(message.payload)
    raise "expected msg_type 1" unless decoded.fetch("msg_type").eql?(1)
    raise "expected piece 0" unless decoded.fetch("piece").eql?(0)
    total_size = decoded.fetch("total_size")
    raise "expected total_size #{total_size}, got #{remaining.length}" unless total_size.eql?(remaining.length)

    metainfo_file = MetainfoFile.from_magnet_link(magnet_link, BencodeDecoder.decode(remaining))
    puts "Tracker URL: #{metainfo_file.tracker_url}"
    puts "Length: #{metainfo_file.length}"
    puts "Info Hash: #{metainfo_file.info_hash}"
    puts "Piece Length: #{metainfo_file.piece_length}"
    puts "Piece Hashes:"
    metainfo_file.pieces.each do |piece|
      puts piece.hash
    end
  rescue PeerConnection::PeerDisconnectedError => e
    puts e.message
    exit 1
  end
end
