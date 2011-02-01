module ShareCounts
  module Reddit
    extend Common
    extend Caching
    
    def self.info_for url 
      try("reddit-details", url) {
        extract_info from_json( "http://www.reddit.com/api/info.json", :url => url ), 
          :selector => "data/children/data" 
      }
    end
  end
end