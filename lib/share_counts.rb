%w(rest_client json nokogiri).each{|x| require x}

module ShareCounts
  def self.make_request *args
    url      = args.shift
    params   = args.inject({}) { |r, c| r.merge! c }
    response = RestClient.get url, { :params => params }
    params.keys.include?(:callback) ? response.gsub(/^(.*);+\n*$/, "\\1").gsub(/^#{params[:callback]}\((.*)\)$/, "\\1") : response
  end
  
  def self.from_json *args
    JSON.parse make_request *args
  end
  
  def self.extract_count *args
    json = args.shift
    result = args.first.flatten.last.split("/").inject( json.is_a?(Array) ? json.first : json ) { 
      |r, c| r[c].is_a?(Array) ? r[c].first : r[c] 
    }
  end

  def self.reddit url
    extract_count from_json( "http://www.reddit.com/api/info.json", :url => url ), :selector => "data/children/data/score" 
  end
  
  def self.digg url
    extract_count from_json( "http://services.digg.com/2.0/story.getInfo", :links => url ), :selector => "stories/diggs"
  end
  
  def self.twitter url
    extract_count from_json( "http://urls.api.twitter.com/1/urls/count.json", :url => url, :callback => "x" ), :selector => "count"
  end

  def self.facebook url
     extract_count from_json("http://api.facebook.com/restserver.php", :v => "1.0", :method => "links.getStats",  
      :urls => url, :callback => "fb_sharepro_render", :format => "json" ), :selector => "share_count"
  end

  def self.fblike url
     extract_count from_json("http://api.facebook.com/restserver.php", :v => "1.0", :method => "links.getStats",  
      :urls => url, :callback => "fb_sharepro_render", :format => "json" ), :selector => "like_count"
  end
  
  def self.fball url 
    json = from_json("http://api.facebook.com/restserver.php", :v => "1.0", :method => "links.getStats",  
     :urls => url, :callback => "fb_sharepro_render", :format => "json" ).first.select{ |k,v| ["share_count", "like_count"].include? k }
  end

  def self.linkedin url 
    extract_count from_json("http://www.linkedin.com/cws/share-count", 
      :url => url, :callback => "IN.Tags.Share.handleCount" ), :selector => "count"
  end

  def self.googlebuzz url 
    from_json("http://www.google.com/buzz/api/buzzThis/buzzCounter", 
      :url => url, :callback => "google_buzz_set_count" )[url]
  end


  def self.stumbleupon url 
    Nokogiri::HTML.parse( make_request("http://www.stumbleupon.com/badge/embed/5/", :url => url ) ).xpath( "//body/div/ul/li[2]/a/span").text.to_i
  end
  
  def self.all url
    %w(reddit digg twitter facebook fblike linkedin googlebuzz stumbleupon).inject({}) { |r, c| r[c.to_sym] = SocialCounts.send(c, url); r }
  end

end
