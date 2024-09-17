require "json"
require "stringio"
require "zeitwerk"
require "socket"

$stdout.sync = true

loader = Zeitwerk::Loader.new
loader.push_dir(File.join(__dir__, "lib"))
loader.setup

if ARGV.length < 2
  puts "Usage: your_bittorrent.sh <command> <args>"
  exit 1
end

command = ARGV[0]

case command
when "decode"
  decoded = BencodeDecoder.decode(ARGV[1])
  puts JSON.generate(decoded)
when "info"
  metainfo_file = MetainfoFile.parse(File.read(ARGV[1]))
  puts "Tracker URL: #{metainfo_file.tracker_url}"
  puts "Length: #{metainfo_file.length}"
  puts "Info Hash: #{metainfo_file.info_hash}"
  puts "Piece Length: #{metainfo_file.piece_length}"
  puts "Piece Hashes:"

  metainfo_file.pieces.each do |piece|
    puts piece.hash
  end
when "peers"
  metainfo_file = MetainfoFile.parse(File.read(ARGV[1]))
  peer_addresses = TrackerClient.new.get_peer_addresses(metainfo_file)

  peer_addresses.each do |peer_address|
    puts "#{peer_address.ip}:#{peer_address.port}"
  end
when "handshake"
  metainfo_file = MetainfoFile.parse(File.read(ARGV[1]))
  peer_ip, peer_port = ARGV[2].split(":")
  peer_connection = PeerConnection.new(metainfo_file, PeerAddress.new(peer_ip, peer_port))
  handshake = peer_connection.perform_handshake!
  puts "Peer ID: #{handshake.peer_id}"
when "download_piece"
  require "optparse"

  output_file_path = nil

  OptionParser.new do |opts|
    opts.banner = "Usage: ./your_bittorrent.sh download_piece [options] <torrent_file> <piece_index>"

    opts.on("-o", "--output FILE", "Output file") do |file|
      output_file_path = file
    end
  end.parse!

  torrent_file_path = ARGV[1]
  piece_index = ARGV[2].to_i

  raise OptionParser::MissingArgument, "Output file is required" if output_file_path.nil?
  raise OptionParser::MissingArgument, "Torrent file is required" if torrent_file_path.nil?
  raise OptionParser::MissingArgument, "Piece index is required" if piece_index.nil?

  metainfo_file = MetainfoFile.parse(File.read(torrent_file_path))
  peer_addresses = TrackerClient.new.get_peer_addresses(metainfo_file)
  piece = metainfo_file.pieces[piece_index]

  raise "piece index out of bounds (#{piece_index} >= #{metainfo_file.pieces.length})" if piece.nil?

  peer_connection = PeerConnection.new(metainfo_file, peer_addresses.first)
  peer_connection.perform_handshake!
  peer_connection.wait_for_bitfield!
  peer_connection.send_interested!
  peer_connection.wait_for_unchoke!

  block_data_list = piece.blocks.map do |block|
    peer_connection.send_request!(block)
    data = peer_connection.wait_for_piece!(block)
    puts "Downloaded block #{block.index} of piece #{piece.index}"
    data
  end

  File.write(output_file_path, block_data_list.join)
else
  raise "unsupported command #{command}"
end
