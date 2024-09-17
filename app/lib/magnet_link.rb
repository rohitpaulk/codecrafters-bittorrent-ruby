class MagnetLink
  def initialize(raw)
    @raw = raw
  end

  def parsed_data
    uri = URI(@raw)
    params = CGI.parse(uri.query)

    {
      "xt" => params["xt"]&.first,
      "dn" => params["dn"]&.first,
      "tr" => params["tr"]
    }.compact
  end

  def info_hash
    prefix, hash = parsed_data["xt"].rsplit(":", 1)
    raise "Invalid xt prefix #{prefix}" unless prefix == "urn:btih"
    hash
  end

  def tracker_urls
    parsed_data["tr"]
  end
end
