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

  def tracker_urls
    parsed_data["tr"]
  end
end
