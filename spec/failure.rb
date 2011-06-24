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

remote_describe "java exception" do

  it "should toss an error loading non-existent gems" do
    require 'java'
    java.lang.System.getProperty(nil)
  end

end
