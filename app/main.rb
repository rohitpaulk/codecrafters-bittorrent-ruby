require "json"
require "stringio"
require "zeitwerk"
require "socket"

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

  metainfo_file.piece_hashes.each do |hash|
    puts "#{hash}"
  end
when "peers"
  metainfo_file = MetainfoFile.parse(File.read(ARGV[1]))
  peers = TrackerClient.new.get_peers(metainfo_file)

  peers.each do |peer|
    puts "#{peer.ip}:#{peer.port}"
  end
when "handshake"
  metainfo_file = MetainfoFile.parse(File.read(ARGV[1]))
  peer_ip, peer_port = ARGV[2].split(":")
  handshake = PeerHandshake.new(metainfo_file.info_hash, "00112233445566778899")
  socket = TCPSocket.new(peer_ip, peer_port)
  socket.write(handshake.to_bytes)
  response = socket.read(68)
  handshake = PeerHandshake.from_bytes(response)

  if handshake.info_hash != metainfo_file.info_hash
    raise "info hash mismatch (expected #{metainfo_file.info_hash}, got #{handshake.info_hash})"
  end

  puts "Peer ID: #{handshake.peer_id}"
else
  raise "unsupported command #{command}"
end
