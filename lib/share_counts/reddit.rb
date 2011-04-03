module ShareCounts
  module Reddit
    extend Common
    extend Caching
    
    def self.info_for url, raise_exceptions = false
      try("reddit-details", url, raise_exceptions) {
        data = extract_info from_json( "http://www.reddit.com/api/info.json", :url => url ), :selector => "data/children/data" 
        ShareCounts.to_merged_hash(data.select{|k, v| ["permalink", "score"].include? k }.map{|x| { x[0] => x[1] } })
      }
    end
    
    def self.by_domain domain, raise_exceptions = false
      try("reddit-domain", domain, raise_exceptions) {
        urls = extract_info from_json("http://www.reddit.com/domain/#{domain}.json"), :selector => "data/children", :preserve_arrays => true 
        urls.inject({}) do |result, url_all_info|
          url_data    = extract_info(url_all_info, :selector => "data").reject{ |key, value| !["permalink", "score", "url"].include? key } 
          url         = url_data.delete "url"
          p url
          result[url] = url_data
          
          result
        end
      }
    end
    
  end
end