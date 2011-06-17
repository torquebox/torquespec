require 'torquespec'
require 'torquebox-core'
require 'jruby'
JRuby.objectspace = true

remote_describe "injection tests" do

  include TorqueBox::Injectors

  deploy <<-END.gsub(/^ {4}/,'')
    queues:
      tweets:
  END

  it "should work" do
    queue = inject_queue('tweets')
    queue.publish('bar')
    queue.receive.should == 'bar'
  end

end

