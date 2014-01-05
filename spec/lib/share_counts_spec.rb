require_relative "../../lib/share_counts"
require_relative "../spec_helper"

describe ShareCounts do
  let(:url) { "http://vitobotta.com/awesomeprint-similar-production/" }
  let(:sc) { ShareCounts.new(url) }

  describe "#reddit_count" do
    it "returns the count of shares on Reddit" do
      sc.reddit_count.should == 7
    end
  end
end
