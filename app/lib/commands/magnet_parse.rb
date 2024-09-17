require "uri"
require "cgi"

module Commands
  class MagnetParse
    def self.run(args)
      if args.length != 2
        puts "Usage: your_bittorrent.sh magnet_parse <magnet_link>"
        exit(1)
      end

      magnet_link_str = args[1]
      magnet_link = MagnetLink.new(magnet_link_str)
      puts "Tracker URL: #{magnet_link.tracker_urls.first}"
    end
  end
end
