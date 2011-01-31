module ShareCounts
  module Caching

    # 
    # 
    # Returns true if the Redis
    # cache store has been initialised
    # 
    # 
    def cache_enabled?
      !$share_counts_cache.nil?
    end



    # 
    # 
    # Removes from Redis cache store all the keys 
    # used by ShareCounts.
    # 
    # 
    def clear_cache
      ($share_counts_cache || {}).keys.select{|cache_key| cache_key =~ /^ShareCounts/ }.each{|cache_key| 
        $share_counts_cache.del cache_key}
    end


    # 
    # 
    # Returns the cached share counts available for each URL, in the format
    # 
    # { 
    #   "URL 1": {
    #     :reddit      => N, 
    #     :digg        => N, 
    #     :twitter     => N, 
    #     :facebook    => N, 
    #     :fblike      => N, 
    #     :linkedin    => N, 
    #     :googlebuzz  => N, 
    #     :stumbleupon => N
    #   },
    #   
    #   "URL 2": {
    #     ...
    #   }
    # }
    # 
    # 
    def cached
      urls = ($share_counts_cache || {}).keys.select{|k| k =~ /^ShareCounts/ }.inject({}) do |result, key|
        data = key.split("||"); network = data[1]; url = data[2]; 
        count = from_redis("ShareCounts||#{network}||#{url}")
        (result[url] ||= {})[network.to_sym] = count unless ["all", "fball"].include? network
        result
      end
      urls
    end

    # 
    # 
    # Enables caching with Redis. 
    # 
    # By default, it connects to 127.0.0.1:6379, but it is also
    # possible to specify in the arguments :host, :port the
    # connection details.
    # 
    # If the application using this gem is already using Redis too,
    # with the "redis" gem, it is possible to use the existing 
    # instance of Redis by either setting the :redist_store argument
    # or by setting the global variable $share_counts_cache first.
    # 
    # 
    def use_cache *args
      arguments = args.inject({}) { |r, c| r.merge(c) }
      $share_counts_cache ||= arguments[:redis_store] || 
        Redis.new(:host => arguments[:host] || "127.0.0.1", :port => arguments[:port] || "6379")  
    end


    private 

    # 
    # 
    # Caches the given value in Redis under the key specified.
    # By default the value is cached for two minutes, but it
    # is also possible to override this expiration time by 
    # setting the global variable $share_counts_cache_expire 
    # to a number of seconds.
    # 
    # 
    def to_redis(cache_key, value)
      $share_counts_cache.set cache_key, Marshal.dump(value)
      $share_counts_cache.expire cache_key, $share_counts_cache_expire || 120
      value
    end


    # 
    # 
    # Retrieves the value stores in Redis under 
    # the given key.
    # 
    # 
    def from_redis(cache_key)
      value = $share_counts_cache.get(cache_key)
      return if value.nil?
      Marshal.load value
    end

  end
end
