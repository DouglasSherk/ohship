require 'net/http'
require 'nokogiri'

module USPS
  API_URL = 'http://production.shippingapis.com/ShippingAPI.dll'
  USER_ID = '868SCIGI7323'

  def self.parse_dimensions(str)
    dims = []
    cur_length = 0.0
    str.gsub(/[^0-9\/"]/, ' ').split.each do |num|
      inch_mark = num['"']
      num = num.delete('"')
      if num['/']
        a, b = num.split('/')
        cur_length += a.to_f / b.to_f
      elsif !num.empty?
        cur_length += num.to_i
      end

      if inch_mark
        dims << cur_length
        cur_length = 0.0
      end
    end

    return dims
  end

  def self.get_shipping_estimate(package)
    pounds = package.weight_lb.to_i
    ounces = ((package.weight_lb - pounds) * 16).round
    if ounces == 16
      pounds += 1
      ounces = 0
    end

    height = package.is_envelope == 1 ? 0.5 : package.height_in
    length, width, height = pkg_dims = [package.length_in, package.width_in, height].sort.reverse

    machinable = true

    url = URI.parse(API_URL)
    req = Net::HTTP::Get.new(url.path + '?API=IntlRateV2&XML=' + URI.encode_www_form_component(
     "<IntlRateV2Request USERID='#{USER_ID}'>
        <Revision>2</Revision>
        <Package ID='0'>
          <Pounds>#{pounds}</Pounds>
          <Ounces>#{ounces}</Ounces>
          <Machinable>#{machinable.to_s}</Machinable>
          <MailType>all</MailType>
          <ValueOfContents>#{package.value}</ValueOfContents>
          <Country>#{package.ship_to_country}</Country>
          <Container>RECTANGULAR</Container>
          <Size>Regular</Size>
          <Width>#{width}</Width>
          <Length>#{length}</Length>
          <Height>#{height}</Height>
          <Girth>#{(width + height) * 2}</Girth>
          <CommercialFlag>n</CommercialFlag>
        </Package>
      </IntlRateV2Request>".gsub(/(  |\n)/, '')))

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.request(req)
    end

    min_cost = {}

    xml = Nokogiri::XML(res.body)
    xml.xpath('//Service').each do |service|
      name = service.at_xpath('SvcDescription').content.delete('*')
      next if name[/box/i] || name['GXG'] # we don't want these

      cost = service.at_xpath('Postage').content.to_f
      p cost.to_s + ': ' + name

      dims = service.at_xpath('MaxDimensions').content

      if is_envelope = name.ends_with?('Envelope')
        # Packages don't fit in envelopes (but vice versa is fine)
        next if package.is_envelope == 0

        # Envelope dimension constraints aren't calculated. Do it ourselves
        max_lengths = parse_dimensions(dims)

        ok = true
        max_lengths.each_with_index do |length, i|
          if pkg_dims[i] > length+1e-9
            ok = false
          end
        end

        next if !ok
      end

      if name.starts_with?('Priority Mail International')
        type = 'priority'
      elsif name.starts_with?('Priority Mail Express International')
        type = 'priority_express'
      elsif name.starts_with?('First-Class')
        type = 'first_class'
      else
        next # don't recognize this class
      end

      if min_cost[type].nil? || cost < min_cost[type]
        min_cost[type] = cost
      end
    end

    return min_cost
  end
end
