require 'torquespec'
require 'open-uri'

TorqueSpec.lazy = true

describe "simple deployment" do
  
  deploy File.join( File.dirname(__FILE__), "../apps/simple.knob" )

  it "should greet the world" do
    response = open("http://localhost:8080") {|f| f.read}
    response.strip.should == "Hello World!"
  end
end
