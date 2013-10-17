module GeoipHelper
  # XXX: This is really slow. We should cache it instead.
  def country
    geoip = GeoIP.new(Rails.root.join("db", "GeoIP.dat"))
    remote_ip = request.remote_ip
    if remote_ip == "127.0.0.1"
      "your country"
    else
      country = geoip.country(remote_ip).country_name
      if country.nil?
        "your country"
      elsif country == "United States"
        "the United States"
      else
        country
      end
    end
  end
end
