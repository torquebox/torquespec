require 'torquespec'
require 'open-uri'

require 'jruby'
JRuby.objectspace = true

remote_describe "in-container tests" do

  deploy <<-END.gsub(/^ {4}/,'')
    application:
      root: #{File.dirname(__FILE__)}/../apps/simple
  END

  it "should still greet the world" do
    response = open("http://localhost:8080") {|f| f.read}
    response.strip.should == "Hello World!"
  end

  it "should work" do
    require 'torquebox/messaging/queue'
    queue = TorqueBox::Messaging::Queue.start('/queues/foo', :jndi => "")
    queue.publish('bar')
    queue.receive.should == 'bar'
    queue.stop
  end

  context "nested example group" do
    it "should work" do
      true.should be_true
    end

    it "should also work" do
      false.should be_false
    end
  end

end

