require "vcr"



VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock # or :fakeweb
end

# VCR.config do |config|
#   config.allow_http_connections_when_no_cassette = true
#   config.cassette_library_dir = "spec/cassettes"
#   config.stub_with :webmock
#   config.default_cassette_options = {
#     :record => :once,
#     :match_requests_on => [:uri, :method, :body],
#     :update_content_length_header => true
#   }
# end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.around(:each) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").gsub(/\s+/, "_").gsub(/[^\w\/]+/, "_")
    VCR.use_cassette(name) { example.call }
  end
end
