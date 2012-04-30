require 'torquespec'
require 'open-uri'
require 'torquebox-messaging'


describe "simple backgrounding" do
  
  deploy <<-DD_END.gsub(/^ {4}/,'')
    application:
      root: #{File.dirname(__FILE__)}/../apps/background
  DD_END

  it "should respond by spawning a background task" do
    response = open("http://localhost:8080") {|f| f.read}
    response.strip.should == "success"
    TorqueBox::Messaging::Queue.new('/queue/background').publish('release')
    TorqueBox::Messaging::Queue.new('/queue/foreground').receive(:timeout => 5000).should == 'success'
  end

end

