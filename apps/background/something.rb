require 'torquebox-messaging'

class Something
  include TorqueBox::Messaging::Backgroundable
  include TorqueBox::Injectors
  
  always_background :foo

  def foo
    if "release" == inject("/queue/background").receive(:timeout => 5000)
      inject("/queue/foreground").publish "success"
    end
  end
  
end
