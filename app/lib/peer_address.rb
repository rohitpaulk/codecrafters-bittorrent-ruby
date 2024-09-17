class PeerAddress
  attr_accessor :ip, :port

  def initialize(ip, port)
    @ip = ip
    @port = port
  end

  def to_s
    "<Peer #{ip}:#{port}>"
  end
end