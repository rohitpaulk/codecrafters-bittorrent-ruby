require "optparse"

class Commands::MagnetDownloadPiece
  def self.run(argv)
    output_file_path = nil

    OptionParser.new do |opts|
      opts.banner = "Usage: ./your_bittorrent.sh magnet_download_piece [options] <magnet_link> <piece_index>"

      opts.on("-o", "--output FILE", "Output file") do |file|
        output_file_path = file
      end
    end.parse!(argv)

    magnet_link = argv[1]
    piece_index = argv[2].to_i

    raise OptionParser::MissingArgument, "Output file is required" if output_file_path.nil?
    raise OptionParser::MissingArgument, "Magnet link is required" if magnet_link.nil?
    raise OptionParser::MissingArgument, "Piece index is required" if piece_index.nil?

    metainfo_file = MagnetLinkMetadataFetcher.new.fetch!(magnet_link)
    peer_addresses = TrackerClient.new.get_peer_addresses(metainfo_file.tracker_url, metainfo_file.info_hash)
    peer_address = peer_addresses.first
    piece = metainfo_file.pieces[piece_index]

    raise "piece index out of bounds (#{piece_index} >= #{metainfo_file.pieces.length})" if piece.nil?

    peer_connection = PeerConnection.new(metainfo_file.info_hash, peer_address)
    peer_connection.perform_handshake!
    peer_connection.wait_for_bitfield!
    peer_connection.send_interested!
    peer_connection.wait_for_unchoke!

    piece_data = peer_connection.download_piece!(piece)
    File.write(output_file_path, piece_data)
  end
end
