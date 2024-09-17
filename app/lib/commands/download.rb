require "optparse"

class Commands::Download
  def self.run(argv)
    output_file_path = nil

    OptionParser.new do |opts|
      opts.banner = "Usage: ./your_bittorrent.sh download_file [options] <torrent_file>"

      opts.on("-o", "--output FILE", "Output file") do |file|
        output_file_path = file
      end
    end.parse!(argv)

    torrent_file_path = argv[1]

    raise OptionParser::MissingArgument, "Output file is required" if output_file_path.nil?
    raise OptionParser::MissingArgument, "Torrent file is required" if torrent_file_path.nil?

    metainfo_file = MetainfoFile.parse(File.read(torrent_file_path))
    peer_addresses = TrackerClient.new.get_peer_addresses(metainfo_file.tracker_url, metainfo_file.info_hash)

    peer_connection = PeerConnection.new(metainfo_file.info_hash, peer_addresses.first)
    peer_connection.perform_handshake!
    peer_connection.wait_for_bitfield!
    peer_connection.send_interested!
    peer_connection.wait_for_unchoke!

    piece_data_list = metainfo_file.pieces.map do |piece|
      block_data_list = piece.blocks.map do |block|
        peer_connection.send_request!(block)
        data = peer_connection.wait_for_piece!(block)
        puts "Downloaded block #{block.index} of piece #{piece.index}"
        data
      end

      block_data_list
    end

    File.write(output_file_path, piece_data_list.join)
  end
end
