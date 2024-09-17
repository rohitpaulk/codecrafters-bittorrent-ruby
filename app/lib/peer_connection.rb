class PeerConnection
  def initialize(metainfo_file, peer_address)
    @metainfo_file = metainfo_file
    @peer_address = peer_address
  end

  def perform_handshake!
    raise "handshake already performed" unless @socket.nil?

    @socket = TCPSocket.new(@peer_address.ip, @peer_address.port)
    outgoing_handshake = PeerHandshake.new(@metainfo_file.info_hash, "00112233445566778899")
    puts "→ #{outgoing_handshake}"
    @socket.write(outgoing_handshake.to_bytes)
    incoming_handshake = PeerHandshake.from_bytes(@socket.read(68))

    if incoming_handshake.info_hash != @metainfo_file.info_hash
      raise "info hash mismatch (expected #{@metainfo_file.info_hash}, got #{incoming_handshake.info_hash})"
    end

    puts "← #{incoming_handshake}"

    incoming_handshake
  end

  def send_interested!
    send_message!(PeerMessage.new(2, ""))
  end

  def send_message!(message)
    raise "handshake not performed" if @socket.nil?

    puts "→ #{message}"
    message.write(@socket)
  end

  def wait_for_bitfield!
    message = wait_for_message!
    raise "expected bitfield message, got #{message.type}" unless message.type.eql?(:bitfield)
  end

  def wait_for_message!
    raise "handshake not performed" if @socket.nil?

    PeerMessage.read(@socket).tap { |message| puts "← #{message}" }
  end

  def wait_for_unchoke!
    message = wait_for_message!
    raise "expected unchoke message, got #{message.type}" unless message.type.eql?(:unchoke)
  end
end
