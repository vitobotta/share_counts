module ShareCountsCommon

  private

  def try service, url, &block
    cache_key = "ShareCounts||#{service}||#{url}"
    if $share_counts_cache.nil?
      puts "Redis caching is disabled - Making request to #{service}..."
      yield
    elsif result = from_redis(cache_key)
      puts "Loaded #{service} count from cache"
      result
    else
      puts "Making request to #{service}..."
      to_redis(cache_key, yield)
    end
     
  rescue Exception => e
    puts "Something went wrong with #{service}: #{e}"
  end

  def make_request *args
    result = nil
    
    timeout(2) do
      url         = args.shift
      params      = args.inject({}) { |r, c| r.merge! c }
      response    = RestClient.get url,  { :params => params }

      result = params.keys.include?(:callback) \
        ? response.gsub(/^(.*);+\n*$/, "\\1").gsub(/^#{params[:callback]}\((.*)\)$/, "\\1") \
        : response
    end
    
    result
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