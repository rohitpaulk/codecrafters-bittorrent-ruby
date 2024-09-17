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

command_class = {
  "decode" => Commands::Decode,
  "info" => Commands::Info,
  "peers" => Commands::Peers,
  "handshake" => Commands::Handshake,
  "download_piece" => Commands::DownloadPiece,
  "download" => Commands::Download
}[command]

if command_class.nil?
  raise "unsupported command #{command}"
end

command_class.run(ARGV)
