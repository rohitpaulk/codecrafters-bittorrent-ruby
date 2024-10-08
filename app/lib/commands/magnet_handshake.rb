class Commands::MagnetHandshake
  def self.run(argv)
    magnet_link = MagnetLink.new(argv[1])
    peer_addresses = TrackerClient.new.get_peer_addresses(magnet_link.tracker_urls.first, magnet_link.info_hash)
    peer_connection = PeerConnection.new(magnet_link.info_hash, peer_addresses.first)
    handshake = peer_connection.perform_handshake!
    peer_connection.wait_for_bitfield!
    puts "Peer ID: #{handshake.peer_id}"

    if handshake.supports_extension_protocol?
      puts "Peer supports extension protocol"
      handshake = peer_connection.perform_extension_handshake!
      puts "Peer Metadata Extension ID: #{BencodeDecoder.decode(handshake.payload).fetch("m").fetch("ut_metadata")}"
    else
      puts "Peer does not support extension protocol"
      exit 1
    end
  rescue PeerConnection::PeerDisconnectedError => e
    puts e.message
    exit 1
  end
end
