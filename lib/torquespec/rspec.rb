require 'torquespec/server'

begin
  # RSpec v2
  require 'rspec'
  TorqueSpec::Configurator = RSpec
rescue Exception
  # RSpec v1
  require 'spec'
  TorqueSpec::Configurator = Spec::Runner
end

# Global configuration
TorqueSpec::Configurator.configure do |config|

  # Add :deploy method to ExampleGroups
  config.extend(TorqueSpec)

  config.before(:suite) do
    Thread.current[:app_server] = TorqueSpec::Server.new
    Thread.current[:app_server].start(:wait => 120)
  end
  
  config.before(:all) do
    if self.class.respond_to?( :deploy_paths )
      self.class.deploy_paths.each do |path|
        Thread.current[:app_server].deploy(path)
      end
    end
  end

  config.after(:all) do
    if self.class.respond_to?( :deploy_paths )
      self.class.deploy_paths.each do |path|
        Thread.current[:app_server].undeploy(path)
      end
    end
  end

  config.after(:suite) do
    Thread.current[:app_server].stop
  end

end
