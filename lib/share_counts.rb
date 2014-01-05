%w( rest_client json nokogiri redis timeout ).each{ |lib| require lib }
# %w( caching common reddit ).each{ |file| load File.expand_path( File.join( File.dirname( __FILE__ ), "share_counts", "#{file}.rb" ) ) } # TODO: replace load with require


class ShareCounts < Struct.new(:url)
  def reddit_count
    json = JSON.parse( RestClient.get "http://www.reddit.com/api/info.json",  params: { url: url } )
    json["data"]["children"][0]["data"]["score"].to_i
  end
end


# module ShareCountsx
# 
#   extend Common
#   extend Caching
# 
#   def self.extract_count *args
#     extract_info *args
#   end
# 
#   def self.supported_networks
#     %w(reddit digg twitter facebook fblike linkedin googlebuzz stumbleupon)
#   end
# 
#   def self.reddit url
#     try("reddit", url) {
#       extract_count from_json( "http://www.reddit.com/api/info.json", :url => url ), 
#         :selector => "data/children/data/score" 
#     }
#   end
# 
#   def self.reddit_with_permalink url
#     ShareCounts::Reddit.info_for url
#   end
# 
#   def self.digg url
#     try("digg", url) {
#       extract_count from_json( "http://services.digg.com/2.0/story.getInfo", :links => url ), 
#         :selector => "stories/diggs"
#     }
#   end
# 
#   def self.twitter url
#     try("twitter", url) {
#       extract_count from_json( "http://urls.api.twitter.com/1/urls/count.json", :url => url), 
#         :selector => "count"
#     }
#   end
# 
#   def self.facebook url
#     try("facebook", url) {
#       extract_count from_json("http://api.facebook.com/restserver.php", :v => "1.0", :method => "links.getStats",  
#        :urls => url, :callback => "fb_sharepro_render", :format => "json" ), :selector => "share_count"
#     }
#   end
# 
#   def self.fblike url
#     try("fblike", url) {
#       extract_count from_json("http://api.facebook.com/restserver.php", :v => "1.0", :method => "links.getStats",  
#        :urls => url, :callback => "fb_sharepro_render", :format => "json" ), :selector => "like_count"
#     }
#   end
# 
#   def self.fball url 
#     try("fball", url) {
#       json = from_json("http://api.facebook.com/restserver.php", :v => "1.0", 
#           :method => "links.getStats", :urls => url, :callback => "fb_sharepro_render", :format => "json" 
#        ).first.select{ |k,v| ["share_count", "like_count"].include? k }
#     }
#   end
# 
#   def self.linkedin url 
#     try("linkedin", url) {
#       extract_count from_json("http://www.linkedin.com/cws/share-count", 
#         :url => url, :callback => "IN.Tags.Share.handleCount" ), :selector => "count"
#     }
#   end
# 
#   def self.googlebuzz url 
#     try("googlebuzz", url) {
#       from_json("http://www.google.com/buzz/api/buzzThis/buzzCounter", 
#         :url => url, :callback => "google_buzz_set_count" )[url]
#     }
#   end
# 
#   def self.stumbleupon url 
#     try("stumbleupon", url) {
#       Nokogiri::HTML.parse( 
#           make_request("http://www.stumbleupon.com/badge/embed/5/", :url => url ) 
#         ).xpath( "//body/div/ul/li[2]/a/span").text.to_i
#     }
#   end
# 
#   def self.all url
#     supported_networks.inject({}) { |r, c| r[c.to_sym] = ShareCounts.send(c, url); r }
#   end
# 
#   def self.selected url, selections
#     selections.map{|name| name.downcase}.select{|name| supported_networks.include? name.to_s}.inject({}) {
#        |r, c| r[c.to_sym] = ShareCounts.send(c, url); r }
#   end
# 
# end
# 
