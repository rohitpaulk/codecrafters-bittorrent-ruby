class PeerConnection
  def initialize(info_hash, peer_address)
    @info_hash = info_hash
    @peer_address = peer_address
  end

  def perform_handshake!
    raise "handshake already performed" unless @socket.nil?

    @socket = TCPSocket.new(@peer_address.ip, @peer_address.port)
    outgoing_handshake = PeerHandshake.new(@info_hash, "00112233445566778899", supports_extension_protocol: true)
    puts "→ #{outgoing_handshake}"
    @socket.write(outgoing_handshake.to_bytes)
    incoming_handshake_bytes = @socket.read(68)
    raise "handshake failed (expected 68 bytes, got #{incoming_handshake_bytes.size})" unless incoming_handshake_bytes&.size == 68
    incoming_handshake = PeerHandshake.from_bytes(incoming_handshake_bytes)

    if incoming_handshake.info_hash != @info_hash
      raise "info hash mismatch (expected #{@info_hash}, got #{incoming_handshake.info_hash})"
    end

    puts "  ← #{incoming_handshake}"

    incoming_handshake
  end

  def perform_extension_handshake!
    raise "base handshake not performed" if @socket.nil?

    outgoing_handshake = PeerMessage.new(20, "")
    outgoing_handshake.write(@socket)
    incoming_handshake_message = wait_for_message!
    raise "expected extension handshake message, got #{incoming_handshake_message.type}" unless incoming_handshake_message.type.eql?(:extension)

    # raise "handshake failed (expected 68 bytes, got #{incoming_handshake_bytes.size})" unless incoming_handshake_bytes&.size == 68
    # incoming_handshake = PeerHandshake.from_bytes(incoming_handshake_bytes)

    # if incoming_handshake.info_hash != @info_hash
    #   raise "info hash mismatch (expected #{@info_hash}, got #{incoming_handshake.info_hash})"
    # end

    # puts "  ← #{incoming_handshake}"

    # incoming_handshake
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

  def wait_for_message!
    raise "handshake not performed" if @socket.nil?

    PeerMessage.read(@socket).tap { |message| puts "  ← #{message}" }
  end

  def wait_for_piece!(block)
    message = wait_for_message!
    raise "expected piece message, got #{message.type}" unless message.type.eql?(:piece)

    message_io = StringIO.new(message.payload)
    message_piece_index = message_io.read(4).unpack1("N")
    raise "piece index mismatch (expected #{block.piece.index}, got #{message_piece_index})" unless message_piece_index == block.piece.index

    message_block_start_byte = message_io.read(4).unpack1("N")
    raise "block start byte mismatch (expected #{block.start_byte}, got #{message_block_start_byte})" unless message_block_start_byte == block.start_byte

    message_block_data = message_io.read
    raise "block data mismatch (expected #{block.length} bytes, got #{message_block_data.size})" unless message_block_data.size == block.length

    message_block_data
  end

  def wait_for_unchoke!
    message = wait_for_message!
    raise "expected unchoke message, got #{message.type}" unless message.type.eql?(:unchoke)
  end
end
