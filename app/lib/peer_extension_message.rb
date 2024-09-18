class PeerExtensionMessage
  attr_accessor :id
  attr_accessor :extended_id
  attr_accessor :payload

  def initialize(id, extended_id, payload)
    @id = id
    @extended_id = extended_id
    @payload = payload
  end

  def self.read(socket)
    length = socket.read(4).unpack1("N")
    id = socket.read(1).unpack1("C")
    raise "expected extension message (20), got #{id}" unless id == 20
    extended_id = socket.read(1).unpack1("C")
    payload = socket.read(length - 2)

    new(id, extended_id, payload)
  end

  def to_s
    "<PeerExtensionMessage(extended_id: #{@extended_id}, payload: #{@payload.unpack1("H*")[0, 20]}#{(@payload.length > 10) ? "..." : ""})>"
  end

  def write(socket)
    PeerMessage.new(20, "#{[@extended_id].pack("C")}#{@payload}").write(socket)
  end
end
