require "optparse"
require "concurrent/array"
require "pmap"

class Commands::MagnetDownload
  def self.run(argv)
    output_file_path = nil

    OptionParser.new do |opts|
      opts.banner = "Usage: ./your_bittorrent.sh magnet_download [options] <magnet_link>"

      opts.on("-o", "--output FILE", "Output file") do |file|
        output_file_path = file
      end
    end.parse!(argv)

    magnet_link = MagnetLink.new(argv[1])

    raise OptionParser::MissingArgument, "Output file is required" if output_file_path.nil?
    raise OptionParser::MissingArgument, "Magnet link is required" if magnet_link.nil?

    metainfo_file = MagnetLinkMetadataFetcher.new.fetch!(magnet_link)
    peer_addresses = TrackerClient.new.get_peer_addresses(metainfo_file.tracker_url, metainfo_file.info_hash)

    peer_connections = peer_addresses.map do |peer_address|
      PeerConnection.new(metainfo_file.info_hash, peer_address)
    end

    peer_connections.each do |peer_connection|
      peer_connection.perform_handshake!
      peer_connection.wait_for_bitfield!
      peer_connection.perform_extension_handshake!
      peer_connection.send_interested!
      peer_connection.wait_for_unchoke!
    end

    pending_pieces = Concurrent::Array.new(metainfo_file.pieces)
    completed_pieces = Concurrent::Array.new

    peer_connections.pmap do |peer_connection|
      until pending_pieces.empty?
        piece = pending_pieces.shift

        next if piece.nil?

        data = peer_connection.download_piece!(piece)
        completed_pieces << [piece, data]
      end

      peer_connection.close
    end

    file_data = completed_pieces.sort_by! { |piece, _| piece.index }.map! { |_, data| data }.join("")

    File.write(output_file_path, file_data)
  end
end
