module ShareCounts
  module Common

    def to_merged_hash array
      array.inject({}){|r, c| r.merge!(c); r }
    end

    private

    # 
    # 
    # Given the name of one of the supported social networks and a URL,
    # attempts the execution of the given block to fetch the relevant share count.
    # 
    # If caching with Redis is enabled, it will first try to 
    # fetch the share count from cache instead, if there is a valid 
    # cached value for the combination of network/URL. When a share count is 
    # instead retrieved with an HTTP request to the network's API and 
    # the caching with Redis is enabled, the value fetched is also cached.
    # 
    # NOTE: caching will be skipped if the block fails.
    # 
    # 
    def try service, url, raise_exceptions = false, &block
      cache_key = "ShareCounts||#{service}||#{url}"
      if cache_enabled?
        if result = from_redis(cache_key)
          puts "Loaded #{service} count from cache"
          result
        else
          puts "Making request to #{service}..."
          to_redis(cache_key, yield)
        end
      else
        puts "Redis caching is disabled - Making request to #{service}..."
        yield
      end
    rescue Exception => e
      puts "Something went wrong with #{service}: #{e}"
      raise e if raise_exceptions
    end


    # 
    # 
    # Performs an HTTP request to the given API URL with the specified params
    # and within 2 seconds, and max 3 attempts
    # 
    # If a :callback param is also specified, then it is assumed that the API
    # returns a JSON text wrapped in a call to a method by that callback name,
    # therefore in this case it manipulates the response to extract only
    # the JSON data required.
    # 
    def make_request *args
      result   = nil
      attempts = 1
      url      = args.shift
      params   = args.inject({}) { |r, c| r.merge! c }

      begin
        response    = RestClient.get url,  { :params => params, :timeout => 5 }

        # if a callback is specified, the expected response is in the format "callback_name(JSON data)";
        # with the response ending with ";" and, in some cases, "\n"
        result = params.keys.include?(:callback) \
          ? response.gsub(/^(.*);+\n*$/, "\\1").gsub(/^#{params[:callback]}\((.*)\)$/, "\\1") \
          : response

      rescue Exception => e
        puts "Failed #{attempts} attempt(s) - #{e}"
        attempts += 1
        if attempts <= 3
          retry 
        else
          raise Exception
        end
      end

      result
    end


    # 
    # 
    # Makes an HTTP request with the given URL and params, and assumes 
    # that the response is in JSON format, therefore it returns
    # the parsed JSON.
    # 
    # 
    def from_json *args
      JSON.parse(make_request(*args))
    end

    # 
    # 
    # Most social networks' APIs returns normal JSON data;
    # this method simply extracts directly the share count from
    # the given JSON data, by following a pattern common to the
    # structure of most JSON responses.
    # 
    # It also requires a :selector argument that determines how
    # to "query" the JSON data in a way that emulates XPATH,
    # so to extract the share count.
    # 
    # 
    def extract_info *args
      json    = args.shift
      options = args.inject({}) {|r,c| r.merge(c)}

      result = options[:selector].split("/").inject( json.is_a?(Array) ? json.first : json ) { |r, c|
        (r[c].is_a?(Array) && !options[:preserve_arrays]) ? r[c].first : r[c] 
      }
    end

  end
end
