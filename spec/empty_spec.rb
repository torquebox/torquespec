require 'torquespec'

remote_describe "in-container tests without a deploy call" do

  it "should work" do
    require 'torquebox/messaging/queue'
    queue = TorqueBox::Messaging::Queue.start('/queues/foo', :jndi => "")
    queue.publish('bar')
    queue.receive.should == 'bar'
    queue.stop
  end

end

