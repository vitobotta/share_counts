module ShareCounts
  module Reddit
    extend Common
    extend Caching
    
    def self.info_for url 
      try("reddit-details", url) {
        data = extract_info from_json( "http://www.reddit.com/api/info.json", :url => url ), 
          :selector => "data/children/data" 
          
        data.reject!{ |key| 
            %w( media_embed levenshtein selftext_html selftext likes saved clicked media over_18
                hidden thumbnail subreddit_id is_self created subreddit_id created_utc num_comments
                domain subreddit id author downs name url title ups
               ).include? key
          }
      }
    end
  end
end