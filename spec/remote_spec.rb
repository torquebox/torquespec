require 'torquespec'

remote_describe "in-container tests" do

  deploy <<-END.gsub(/^ {4}/,'')
    application:
      root: #{File.dirname(__FILE__)}/../apps/simple
    services:
      TorqueSpec::Daemon:
        argv: #{ARGV.map{|x|File.expand_path(x)}.inspect}
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

end

