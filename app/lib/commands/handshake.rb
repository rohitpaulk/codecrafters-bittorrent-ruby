class Commands::Handshake
  def self.run(argv)
    metainfo_file = MetainfoFile.parse(File.read(argv[1]))
    peer_ip, peer_port = argv[2].split(":")
    peer_connection = PeerConnection.new(metainfo_file.info_hash, PeerAddress.new(peer_ip, peer_port))
    handshake = peer_connection.perform_handshake!
    puts "Peer ID: #{handshake.peer_id}"
  end
end