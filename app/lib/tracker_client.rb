require 'cgi'
require 'httparty'

class TrackerClient
  def get_peer_addresses(metainfo_file)
    info_hash_bytes = [metainfo_file.info_hash].pack('H*')

    response = HTTParty.get(
      "#{metainfo_file.tracker_url}",
      query: {
        info_hash: info_hash_bytes,
        compact: 1,
        left: metainfo_file.length,
        peer_id: "00112233445566778899",
        port: 6881,
        uploaded: 0,
        downloaded: 0,
      },
    )

    if response.code != 200
      raise "tracker returned #{response.code}: #{response.body}"
    end

    decoded_response = BencodeDecoder.decode(response.body)

    decoded_response.fetch("peers").chars.each_slice(6).map do |peer_bytes|
      ip = peer_bytes[0..3].map(&:ord).join('.')
      port = peer_bytes[4..5].join.unpack1("n")
      PeerAddress.new(ip, port)
    end
  end
end