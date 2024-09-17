class Commands::Info
  def self.run(argv)
    metainfo_file = MetainfoFile.parse(File.read(argv[1]))
    puts "Tracker URL: #{metainfo_file.tracker_url}"
    puts "Length: #{metainfo_file.length}"
    puts "Info Hash: #{metainfo_file.info_hash}"
    puts "Piece Length: #{metainfo_file.piece_length}"
    puts "Piece Hashes:"

    metainfo_file.pieces.each do |piece|
      puts piece.hash
    end
  end
end
