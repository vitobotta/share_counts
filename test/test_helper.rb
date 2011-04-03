%w(rubygems active_support webmock/test_unit stringio system_timer).each{|g| require g}

include WebMock::API

require File.join(File.dirname(__FILE__), "../lib/share_counts")

