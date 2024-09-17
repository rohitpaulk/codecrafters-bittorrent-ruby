class Commands::Peers
  def self.run(argv)
    metainfo_file = MetainfoFile.parse(File.read(argv[1]))
    peer_addresses = TrackerClient.new.get_peer_addresses(metainfo_file)

    peer_addresses.each do |peer_address|
      puts "#{peer_address.ip}:#{peer_address.port}"
    end
  end
end