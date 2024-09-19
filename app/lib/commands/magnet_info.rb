class Commands::MagnetInfo
  def self.run(argv)
    magnet_link = MagnetLink.new(argv[1])
    metainfo_file = MagnetLinkMetadataFetcher.new.fetch!(magnet_link)

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
