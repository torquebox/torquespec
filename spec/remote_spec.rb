require 'torquespec'

remote_describe "in-container tests" do

  deploy <<-END.gsub(/^ {4}/,'')
    application:
      root: #{File.dirname(__FILE__)}/../apps/simple
    services:
      TorqueSpec::Daemon:
        argv: #{TorqueSpec.argv}
        pwd: #{Dir.pwd}
    environment:
      RUBYLIB: #{TorqueSpec.rubylib}
  END

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

