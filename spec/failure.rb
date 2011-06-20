require 'torquespec'

remote_describe "scratch pad for failures" do

  it "should work" do
    fail "That didn't work!"
  end

  describe "nested" do
    it "should also not work" do
      fail "whatever"
    end
  end

end

