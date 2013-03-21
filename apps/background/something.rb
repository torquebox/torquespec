require 'torquebox-messaging'

class Something
  include TorqueBox::Messaging::Backgroundable
  include TorqueBox::Injectors
  
  always_background :foo

  def foo
    if "release" == __inject__("/queue/background").receive(:timeout => 5000)
      __inject__("/queue/foreground").publish "success"
    end
  end
  
end
