%w(rubygems active_support webmock/test_unit stringio).each{|g| require g}

include WebMock::API

require File.join(File.dirname(__FILE__), "../lib/share_counts")

SOME_URL    = "http://vitobotta.com/cv-resume/" 
SOME_PARAMS = [ :url => "http://vitobotta.com/cv-resume/", :callback => "myCallback" ] 

class ActiveSupport::TestCase
  setup do
    $stderr = @stderr = StringIO.new
    $stdin  = @stdin  = StringIO.new
    $stdout = @stdout = StringIO.new
  end

  def teardown
    $stderr = @stderr =  STDERR
    $stdin  = @stdin  =  STDIN
    $stdout = @stdout =  STDOUT
  end
  
  def to_merged_hash array
    ShareCounts.to_merged_hash array
  end
end

class Reddit
  def self.params
    [:url => SOME_URL]
  end
  def self.api  
    "http://www.reddit.com/api/info.json"
  end
  def self.json
    @json ||= File.read(File.join(File.dirname(__FILE__), "reddit.json"))
  end
  def self.url_info_json
    @url_info_json ||= File.read(File.join(File.dirname(__FILE__), "reddit-url-info.json"))
  end
  def self.by_domain_json
    @by_domain_json ||= File.read(File.join(File.dirname(__FILE__), "reddit-by-domain.json"))
  end
  def self.selector
    "data/children/data/score"
  end
end

class Digg
  def self.api
    "http://services.digg.com/2.0/story.getInfo"
  end
  def self.params
    [:links => SOME_URL]
  end
  def self.json
    @json ||= File.read(File.join(File.dirname(__FILE__), "digg.json"))
  end
  def self.selector
    "stories/diggs"
  end
end

class Twitter 
  def self.api
    "http://urls.api.twitter.com/1/urls/count.json"
  end
  def self.params
    [:url => SOME_URL]
  end
  def self.json
    @json ||= File.read(File.join(File.dirname(__FILE__), "twitter.json"))
  end
  def self.selector
    "count"
  end
end

class Facebook
  def self.api
    "http://api.facebook.com/restserver.php"
  end
  def self.json
    @json ||= File.read(File.join(File.dirname(__FILE__), "facebook.json"))
  end
  def self.params
    [:v => "1.0", :method => "links.getStats", :urls => SOME_URL, :callback => "fb_sharepro_render", :format => "json"]
  end
  def self.selector
    "total_count"
  end
end

class Linkedin
  def self.api
    "http://www.linkedin.com/cws/share-count"
  end
  def self.params
    [:url => SOME_URL, :callback => "IN.Tags.Share.handleCount"]
  end
  def self.json
    @json ||= File.read(File.join(File.dirname(__FILE__), "linkedin.json"))
  end
  def self.selector
    "count"
  end
end

class GoogleBuzz
  def self.api
    "http://www.google.com/buzz/api/buzzThis/buzzCounter"
  end
  def self.params
    [:url => SOME_URL, :callback => "google_buzz_set_count"]
  end
  def self.json
    @json ||= File.read(File.join(File.dirname(__FILE__), "googlebuzz.json")) 
  end
end

class StumbleUpon
  def self.api
    "http://www.stumbleupon.com/badge/embed/5/"
  end
  def self.params
    [:url => SOME_URL]
  end
  def self.html
    @json ||= File.read(File.join(File.dirname(__FILE__), "stumbleupon.html"))  
  end
end