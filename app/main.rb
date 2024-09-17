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

case command
when "decode"
  decoded = BencodeDecoder.decode(ARGV[1])
  puts JSON.generate(decoded)
when "info"
  parsed = MetainfoFile.parse(File.read(ARGV[1]))
  puts "Tracker URL: #{parsed.tracker_url}"
  puts "Length: #{parsed.length}"
  puts "Info Hash: #{parsed.info_hash}"
else
  raise "unsupported command #{command}"
end
