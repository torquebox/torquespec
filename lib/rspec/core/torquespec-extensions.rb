begin
  # RSpec v2
  require 'rspec'
  TorqueSpec::Configurator = RSpec
rescue Exception
  # RSpec v1
  require 'spec'
  TorqueSpec::Configurator = Spec::Runner
end

TorqueSpec::Configurator.configure do |config|
  # Add :deploy method to ExampleGroups
  config.extend(TorqueSpec)
end

TorqueSpec.remote {
  module TorqueSpec
    def deploy(*descriptors)
    end
  end
}

TorqueSpec.local {

  require 'torquespec/server'

  TorqueSpec::Configurator.configure do |config|
    config.before(:suite) do
      Thread.current[:app_server] = TorqueSpec::Server.new
      Thread.current[:app_server].start(:wait => 120)
    end
    
    config.before(:all) do
      self.class.deploy_paths.each do |path|
        Thread.current[:app_server].deploy(path)
      end if self.class.respond_to?( :deploy_paths )
    end

    config.after(:all) do
      self.class.deploy_paths.each do |path|
        Thread.current[:app_server].undeploy(path)
      end if self.class.respond_to?( :deploy_paths )
    end

    config.after(:suite) do
      Thread.current[:app_server].stop
    end
  end
}

require 'torquespec/daemon'

module TorqueSpec
  module ObjectExtensions
    def remote_describe(*args, &example_group_block)
      unless TorqueSpec.domain_mode
        group = describe(*args, &example_group_block)
        TorqueSpec.remote? ? group : group.extend( TorqueSpec::Daemon::Client )
      end
    end
  end
end

class Object
  include TorqueSpec::ObjectExtensions
end
