require 'helper'

class TestPlaydarr < Test::Unit::TestCase
  context "The Playdar Server" do
    # We need a playdar server to be running to test!
    should "be running, and return stats" do
      assert PlaydARR::Server.stats
    end
    
    should "return some tracks" do
      assert PlaydARR::Server.search("some artist","some track").is_a? Array
    end
  end
end
