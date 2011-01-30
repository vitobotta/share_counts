%w(rest_client json nokogiri redis).each{|x| require x}

$share_counts_cache_settings = {
  :host    => "127.0.0.1", 
  :port    => "6379"
}

module ShareCountsMethods
  def self.included(base)
    class << base

      def clear_cache
        ($share_counts_cache || {}).keys.select{|cache_key| cache_key =~ /^ShareCounts/ }.each{|cache_key| $share_counts_cache.del cache_key}
      end
      
      def cached
        urls = ($share_counts_cache || {}).keys.select{|k| k =~ /^ShareCounts/ }.inject({}) do |result, key|
          data = key.split("||"); network = data[1]; url = data[2]; count = $share_counts_cache.get key
          (result[url] ||= {})[network.to_sym] = count unless ["all", "fball"].include? network
          result
        end
        urls
      end
      
      def use_cache *args
        arguments = args.inject({}) { |r, c| r.merge(c) }
        $share_counts_cache ||= arguments[:redis_store] || Redis.new(:host => arguments[:host] || $share_counts_cache_settings[:host], :port => arguments[:port] || $share_counts_cache_settings[:port])  
      end
      
      def reddit url
        try("reddit", url) {
          extract_count from_json( "http://www.reddit.com/api/info.json", :url => url ), :selector => "data/children/data/score" 
        }
      end

      def digg url
        try("digg", url) {
          extract_count from_json( "http://services.digg.com/2.0/story.getInfo", :links => url ), :selector => "stories/diggs"
        }
      end

      def twitter url
        try("twitter", url) {
          extract_count from_json( "http://urls.api.twitter.com/1/urls/count.json", :url => url, :callback => "x" ), :selector => "count"
        }
      end

      def facebook url
        try("facebook", url) {
          extract_count from_json("http://api.facebook.com/restserver.php", :v => "1.0", :method => "links.getStats",  
           :urls => url, :callback => "fb_sharepro_render", :format => "json" ), :selector => "share_count"
        }
      end

      def fblike url
        try("fblike", url) {
          extract_count from_json("http://api.facebook.com/restserver.php", :v => "1.0", :method => "links.getStats",  
           :urls => url, :callback => "fb_sharepro_render", :format => "json" ), :selector => "like_count"
        }
      end

      def fball url 
        try("fball", url) {
          json = from_json("http://api.facebook.com/restserver.php", :v => "1.0", :method => "links.getStats",  
           :urls => url, :callback => "fb_sharepro_render", :format => "json" ).first.select{ |k,v| ["share_count", "like_count"].include? k }
        }
      end

      def linkedin url 
        try("linkedin", url) {
          extract_count from_json("http://www.linkedin.com/cws/share-count", 
            :url => url, :callback => "IN.Tags.Share.handleCount" ), :selector => "count"
        }
      end

      def googlebuzz url 
        try("googlebuzz", url) {
          from_json("http://www.google.com/buzz/api/buzzThis/buzzCounter", 
            :url => url, :callback => "google_buzz_set_count" )[url]
        }
      end

      def stumbleupon url 
        try("stumbleupon", url) {
          Nokogiri::HTML.parse( make_request("http://www.stumbleupon.com/badge/embed/5/", :url => url ) ).xpath( "//body/div/ul/li[2]/a/span").text.to_i
        }
      end

      def all url
        try("all", url) {
          %w(reddit digg twitter facebook fblike linkedin googlebuzz stumbleupon).inject({}) { |r, c| r[c.to_sym] = ShareCounts.send(c, url); r }
        }
      end

      private

      def to_redis(cache_key, value)
        $share_counts_cache.set cache_key, value
        $share_counts_cache.expire cache_key, $share_counts_cache_expire || 300
        value
      end

      def from_redis(cache_key)
        $share_counts_cache.get cache_key
      end

      def try service, url, &block
        cache_key = "ShareCounts||#{service}||#{url}"
        $share_counts_cache.nil? ? yield : ( from_redis(cache_key) || to_redis(cache_key, yield) )
      rescue Exception => e
        puts "Something went wrong: #{e}"
      end

      def make_request *args
        # TODO: add timeout
        url      = args.shift
        params   = args.inject({}) { |r, c| r.merge! c }
        response = RestClient.get url, { :params => params }
        params.keys.include?(:callback) ? response.gsub(/^(.*);+\n*$/, "\\1").gsub(/^#{params[:callback]}\((.*)\)$/, "\\1") : response
      end

      def from_json *args
        JSON.parse make_request *args
      end

      def extract_count *args
        json = args.shift
        result = args.first.flatten.last.split("/").inject( json.is_a?(Array) ? json.first : json ) { 
          |r, c| r[c].is_a?(Array) ? r[c].first : r[c] 
        }
      end
    end
  end
end


class ShareCounts
  include ShareCountsMethods
end