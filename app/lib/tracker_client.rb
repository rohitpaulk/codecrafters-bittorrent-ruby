require 'cgi'
require 'httparty'

class TrackerClient
  def get(metainfo_file)
    info_hash_bytes = [metainfo_file.info_hash].pack('H*')
    response = HTTParty.get(
      "#{metainfo_file.tracker_url}",
      query: {
        info_hash: info_hash_bytes,
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

    BencodeDecoder.decode(response.body)
  end
end