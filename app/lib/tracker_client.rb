require 'cgi'
require 'httparty'

class TrackerClient
  def get(tracker_url, info_hash)
    info_hash_bytes = [info_hash].pack('H*')
    response = HTTParty.get("#{tracker_url}", query: { info_hash: info_hash_bytes })

    if response.code != "200"
      raise "tracker returned #{response.code}: #{response.body}"
    end

    BencodeDecoder.decode(response.body)
  end
end