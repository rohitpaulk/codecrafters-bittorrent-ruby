class PeerExtensionMessage
  attr_accessor :extension_id
  attr_accessor :payload

  def initialize(extension_id, payload)
    @extension_id = extension_id
    @payload = payload
  end

  def self.read(socket)
    length = socket.read(4).unpack1("N")
    id = socket.read(1).unpack1("C")
    raise "expected extension message (20), got #{id}" unless id == 20
    extension_id = socket.read(1).unpack1("C")
    payload = socket.read(length - 2)

    new(extension_id, payload)
  end

  def to_s
    "<PeerExtensionMessage(extension_id: #{@extension_id}, payload: #{@payload.unpack1("H*")[0, 20]}#{(@payload.length > 10) ? "..." : ""})>"
  end

  def write(socket)
    PeerMessage.new(20, "#{[@extension_id].pack("C")}#{@payload}").write(socket)
  end
end
