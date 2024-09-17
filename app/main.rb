require "json"
require "stringio"
require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir(File.join(__dir__, "lib"))
loader.setup

if ARGV.length < 2
  puts "Usage: your_bittorrent.sh <command> <args>"
  exit 1
end

command = ARGV[0]

if command == "decode"
  decoded = BencodeDecoder.decode(ARGV[1])
  puts JSON.generate(decoded)
else
  raise "unsupported command #{command}"
end
