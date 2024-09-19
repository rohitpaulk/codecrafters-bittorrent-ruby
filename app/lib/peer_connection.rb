class PeerConnection
  class PeerDisconnectedError < StandardError; end

  def initialize(info_hash, peer_address)
    @info_hash = info_hash
    @peer_address = peer_address
  end

  def close
    @socket&.close
  end

  def download_piece!(piece)
    piece.blocks.each do |block|
      send_request!(block)
    end

    block_data_list = []

    piece.blocks.each do
      block, data = wait_for_piece!(piece)
      puts "Downloaded block #{block.index} of piece #{piece.index}"
      block_data_list << [block, data]
    end

    block_data_list.sort_by! { |block, _| block.index }.map! { |_, data| data }.join("")
  end

  def perform_handshake!
    raise "handshake already performed" unless @socket.nil?

    @socket = TCPSocket.new(@peer_address.ip, @peer_address.port)
    outgoing_handshake = PeerHandshake.new(@info_hash, SecureRandom.hex(10), supports_extension_protocol: true)
    puts "→ #{outgoing_handshake}"
    @socket.write(outgoing_handshake.to_bytes)
    incoming_handshake_bytes = @socket.read(68)

    if incoming_handshake_bytes.nil?
      @socket.close
      raise PeerDisconnectedError, "Peer #{@peer_address} disconnected"
    end

    raise "handshake failed (expected 68 bytes, got #{incoming_handshake_bytes.size})" unless incoming_handshake_bytes.size == 68

    incoming_handshake = PeerHandshake.from_bytes(incoming_handshake_bytes)

    if incoming_handshake.info_hash != @info_hash
      raise "info hash mismatch (expected #{@info_hash}, got #{incoming_handshake.info_hash})"
    end

    puts "  ← #{incoming_handshake}"

    incoming_handshake
  rescue Errno::ECONNRESET
    @socket.close
    raise PeerDisconnectedError, "Peer #{@peer_address} disconnected"
  end

  def perform_extension_handshake!
    raise "base handshake not performed" if @socket.nil?

    outgoing_handshake = PeerExtensionMessage.new(0, BencodeEncoder.encode({"m" => {"ut_metadata" => 6}}))
    puts "→ #{outgoing_handshake}"
    outgoing_handshake.write(@socket)
    incoming_handshake_message = PeerExtensionMessage.read(@socket)
    puts "  ← #{incoming_handshake_message}"
    incoming_handshake_message
  rescue Errno::ECONNRESET
    @socket.close
    raise PeerDisconnectedError, "Peer #{@peer_address} disconnected"
  end

  def send_interested!
    send_message!(PeerMessage.new(2, ""))
  end

  def send_message!(message)
    raise "handshake not performed" if @socket.nil?

    puts "→ #{message}"
    message.write(@socket)
  end

  def send_request!(block)
    payload = [block.piece.index, block.start_byte, block.length].pack("N*")
    send_message!(PeerMessage.new(6, payload))
  end

  def wait_for_bitfield!
    message = wait_for_message!
    raise "expected bitfield message, got #{message.type}" unless message.type.eql?(:bitfield)
  end

  def wait_for_extension_message!
    raise "handshake not performed" if @socket.nil?

    PeerExtensionMessage.read(@socket).tap { |message| puts "  ← #{message}" }
  end

  def wait_for_message!
    raise "handshake not performed" if @socket.nil?

    PeerMessage.read(@socket).tap { |message| puts "  ← #{message}" }
  end

  def wait_for_piece!(piece)
    message = wait_for_message!
    raise "expected piece message, got #{message.type}" unless message.type.eql?(:piece)

    message_io = StringIO.new(message.payload)
    message_piece_index = message_io.read(4).unpack1("N")
    raise "piece index mismatch (expected #{piece.index}, got #{message_piece_index})" unless message_piece_index == piece.index
    block_start_byte = message_io.read(4).unpack1("N")
    block_data = message_io.read

    block = piece.blocks.find do |block|
      block.start_byte == block_start_byte
    end.tap do |block|
      raise "block not found for piece #{piece.index} (start byte #{block_start_byte})" if block.nil?
    end

    [block, block_data]
  end

  def wait_for_unchoke!
    message = wait_for_message!
    raise "expected unchoke message, got #{message.type}" unless message.type.eql?(:unchoke)
  end
end
