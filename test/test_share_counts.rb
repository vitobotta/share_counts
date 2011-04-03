require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class ShareCountsTest < ActiveSupport::TestCase
  A_REMOTE_URL     = "http://www.someservice.com"
  SOME_PARAMS      = [ :url => "http://vitobotta.com/cv-resume/", :callback => "myCallback" ]
  SOME_PARAMS_HASH = SOME_PARAMS.inject({}){|r, c| r.merge!(c); r }
  
  setup do
    $stderr = @stderr = StringIO.new
    $stdin  = @stdin  = StringIO.new
    $stdout = @stdout = StringIO.new
  end
  
  def teardown
    $stderr = STDERR
    $stdin  = STDIN
    $stdout = STDOUT
  end
  
  test ".supported_networks returns the supported networks" do
    assert_equal(%w(reddit digg twitter facebook fblike linkedin googlebuzz stumbleupon).sort, ShareCounts.supported_networks.sort)
  end
  
  test ".make_request makes a request to a remove service and returns the response" do
    stub_request(:get, A_REMOTE_URL).with(:query => SOME_PARAMS_HASH).to_return(:body => "---RESPONSE---")
  
    assert_equal("---RESPONSE---", ShareCounts.send(:make_request, A_REMOTE_URL, *SOME_PARAMS ))
    assert_equal(0, @stdout.string.split("\n").size)
  end
  
  test ".make_request should raise an exception if the remote service returns a 500 status code for three attempts" do
    stub_request(:get, A_REMOTE_URL).to_return(:status =>  [500, "Internal Server Error"])
  
    assert_raise(Exception) { ShareCounts.send(:make_request, A_REMOTE_URL)  }
    
    errors = []
    3.times {|n| errors << "Failed #{n+1} attempt(s) - 500 Internal Server Error" }
    assert_equal(errors.sort, @stdout.string.split("\n").sort)
  end
  
  
  test ".make_request should raise an exception if the remote service times out for three attempts" do
    stub_request(:get, A_REMOTE_URL).to_timeout
    
    assert_raise(Exception) { ShareCounts.send(:make_request, A_REMOTE_URL)  }
    
    errors = []
    3.times {|n| errors << "Failed #{n+1} attempt(s) - Request Timeout" }
    assert_equal(errors.sort, @stdout.string.split("\n").sort)
  end
  
  test ".make_request should return response if remote service fails < 3 attempts" do
    stub_request(:get, A_REMOTE_URL).
      to_return(:status =>  [500, "Internal Server Error"]).then.
      to_timeout.then.
      to_return(:body => "---RESPONSE---" )
    
    assert_nothing_raised(Exception) { assert_equal("---RESPONSE---", ShareCounts.send(:make_request, A_REMOTE_URL)) }
    
    assert_equal(["Failed 1 attempt(s) - 500 Internal Server Error", "Failed 2 attempt(s) - Request Timeout"].sort, @stdout.string.split("\n").sort)
  end

  test ".make_request should strip the callback call from the JSON response if a callback has been specified" do
    stub_request(:get, A_REMOTE_URL).with(:query => SOME_PARAMS_HASH).
      to_return(:body => "myCallback(JSON_DATA);").then.
      to_return(:body => "myCallback(JSON_DATA)")

    assert_equal("JSON_DATA", ShareCounts.send(:make_request, A_REMOTE_URL, *SOME_PARAMS ))
    assert_equal("JSON_DATA", ShareCounts.send(:make_request, A_REMOTE_URL, *SOME_PARAMS ))
    assert_equal(0, @stdout.string.split("\n").size)
  end
  
  
  # test ".from_json converts the JSON returned by a remote service to a hash - no callback specified" do
  #   stub_request(:get, A_REMOTE_URL).with(:query => SOME_PARAMS_HASH).to_return(:body => "---RESPONSE---")
  #   
  #   assert_equal({ :key1 => "value1", :key2 => "value2" } , ShareCounts.from_json(A_REMOTE_URL, *SOME_PARAMS))
  # end
  
end