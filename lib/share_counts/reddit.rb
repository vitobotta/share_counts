module ShareCounts
  module Reddit
    extend Common
    extend Caching
    
    def self.info_for url 
      try("reddit-details", url) {
        data = extract_info from_json( "http://www.reddit.com/api/info.json", :url => url ), :selector => "data/children/data" 

        data.reject{ |key, value| 
            %w( media_embed levenshtein selftext_html selftext likes saved clicked media over_18
                hidden thumbnail subreddit_id is_self created subreddit_id created_utc num_comments
                domain subreddit id author downs name url title ups
               ).include? key
          }
      }
    end
    
    def self.by_domain domain
      try("reddit-domain", domain) {
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