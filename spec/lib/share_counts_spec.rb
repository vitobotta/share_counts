require_relative "../../lib/share_counts"
require_relative "../spec_helper"

describe ShareCounts do
  let(:url) { "http://vitobotta.com/awesomeprint-similar-production/" }
  let(:sc) { ShareCounts.new(url) }

  describe "#reddit_count" do
    it "returns the count of shares on Reddit" do
      # NOTE: actual web request....
      sc.reddit_count.should == 5

      # NOTE: ...and ensuring the return value is not hardcoded by mistake
      RestClient.stub(:get)
      JSON.should_receive(:parse).and_return({ "data" => { "children" => [{ "data" => { "score" => 14 } }] } })
      sc.reddit_count.should == 14
    end
  end
end
