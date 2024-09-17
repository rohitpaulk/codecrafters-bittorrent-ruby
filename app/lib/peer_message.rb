class PeerMessage
  attr_accessor :id
  attr_accessor :payload

  def initialize(id, payload)
    @id = id
    @payload = payload
  end

  def self.read(socket)
    length = socket.read(4).unpack1("N")
    id = socket.read(1).unpack1("C")
    payload = socket.read(length - 1)

    new(id, payload)
  end

  def type
    case @id
    when 0
      :choke
    when 1
      :unchoke
    when 2
      :interested
    when 5
      :bitfield
    when 6
      :request
    when 7
      :piece
    else
      :unknown
    end
  end

  def to_s
    "<PeerMessage(type: #{type}, id: #{@id}, payload: #{@payload.unpack1("H*")[0, 20]}#{(@payload.length > 10) ? "..." : ""})>"
  end

  def write(socket)
    socket.write([@payload.length + 1].pack("N"))
    socket.write([@id].pack("C"))
    socket.write(@payload)
  end
end
