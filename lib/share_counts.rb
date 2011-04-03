%w( rubygems rest_client json nokogiri redis ).each{ |lib| require lib }
%w( array caching common reddit ).each{ |file| load File.expand_path( File.join( File.dirname( __FILE__ ), "share_counts", "#{file}.rb" ) ) } # TODO: replace load with require

module ShareCounts

  extend Common
  extend Caching

  def self.extract_count *args
    extract_info *args
  end

  def self.supported_networks
    %w(reddit digg twitter facebook linkedin stumbleupon googlebuzz)
  end
  
  def self.reddit url, raise_exceptions = false
    try("reddit", url, raise_exceptions) {
      extract_count from_json( "http://www.reddit.com/api/info.json", :url => url ), 
        :selector => "data/children/data/score" 
    }
  end
  
  def self.reddit_with_permalink url, raise_exceptions = false
    ShareCounts::Reddit.info_for url, raise_exceptions
  end
  
  def self.digg url, raise_exceptions = false
    try("digg", url, raise_exceptions) {
      extract_count from_json( "http://services.digg.com/2.0/story.getInfo", :links => url ), 
        :selector => "stories/diggs"
    }
  end

  def self.twitter url, raise_exceptions = false
    try("twitter", url, raise_exceptions) {
      extract_count from_json( "http://urls.api.twitter.com/1/urls/count.json", :url => url), 
        :selector => "count"
    }
  end

  def self.facebook url, raise_exceptions = false
    try("facebook", url, raise_exceptions) {
      extract_count from_json("http://api.facebook.com/restserver.php", :v => "1.0", :method => "links.getStats",  
       :urls => url, :callback => "fb_sharepro_render", :format => "json" ), :selector => "total_count"
    }
  end

  def self.linkedin url, raise_exceptions = false 
    try("linkedin", url, raise_exceptions) {
      extract_count from_json("http://www.linkedin.com/cws/share-count", 
        :url => url, :callback => "IN.Tags.Share.handleCount" ), :selector => "count"
    }
  end

  def self.googlebuzz url, raise_exceptions = false 
    try("googlebuzz", url, raise_exceptions) {
      from_json("http://www.google.com/buzz/api/buzzThis/buzzCounter", 
        :url => url, :callback => "google_buzz_set_count" )[url]
    }
  end

  def self.stumbleupon url, raise_exceptions = false 
    try("stumbleupon", url, raise_exceptions) {
      Nokogiri::HTML.parse( 
          make_request("http://www.stumbleupon.com/badge/embed/5/", :url => url ) 
        ).xpath( "//body/div/ul/li[2]/a/span").text.to_i
    }
  end

  def self.all url
    supported_networks.inject({}) { |r, c| r[c.to_sym] = ShareCounts.send(c, url); r }
  end
  
  def self.selected url, selections
    selections.map{|name| name.downcase}.select{|name| supported_networks.include? name.to_s}.inject({}) {
       |r, c| r[c.to_sym] = ShareCounts.send(c, url); r }
  end
  
end

