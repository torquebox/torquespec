require 'torquespec'
require 'open-uri'

TorqueSpec.lazy = false

describe "simple knob deployment" do
  
  deploy File.join( File.dirname(__FILE__), "../apps/simple.knob" )

  it "should greet the world" do
    response = open("http://localhost:8080") {|f| f.read}
    response.strip.should == "Hello World!"
  end
end

describe "simple directory deployment" do
  
  deploy <<-END.gsub(/^ {4}/,'')
    application:
      root: #{File.dirname(__FILE__)}/../apps/simple
  END

  it "should greet the world" do
    response = open("http://localhost:8080") {|f| f.read}
    response.strip.should == "Hello World!"
  end
end

describe "war deployment" do
  
  deploy File.join( File.dirname(__FILE__), "../apps/node-info.war" )

  it "should greet the world" do
    response = open("http://localhost:8080/node-info") {|f| f.read}
    response.should include( 'JBoss-Cloud node info' )
  end
end

