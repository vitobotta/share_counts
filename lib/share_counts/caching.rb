module ShareCountsCaching

  private 

  def clear_cache
    ($share_counts_cache || {}).keys.select{|cache_key| cache_key =~ /^ShareCounts/ }.each{|cache_key| 
      $share_counts_cache.del cache_key}
  end
  
  def cached
    urls = ($share_counts_cache || {}).keys.select{|k| k =~ /^ShareCounts/ }.inject({}) do |result, key|
      data = key.split("||"); network = data[1]; url = data[2]; 
      count = from_redis("ShareCounts||#{network}||#{url}")
      (result[url] ||= {})[network.to_sym] = count unless ["all", "fball"].include? network
      result
    end
    urls
  end
  
  def use_cache *args
    arguments = args.inject({}) { |r, c| r.merge(c) }
    $share_counts_cache ||= arguments[:redis_store] || 
      Redis.new(:host => arguments[:host] || "127.0.0.1", :port => arguments[:port] || "6379")  
  end


  def to_redis(cache_key, value)
    $share_counts_cache.set cache_key, Marshal.dump(value)
    $share_counts_cache.expire cache_key, $share_counts_cache_expire || 300
    value
  end

  def from_redis(cache_key)
    value = $share_counts_cache.get(cache_key)
    return if value.nil?
    Marshal.load value
  end
  
end