class Commands::Decode
  def self.run(argv)
    decoded = BencodeDecoder.decode(argv[1])
    puts JSON.generate(decoded)
  end
end
