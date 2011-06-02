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

TorqueSpec::Configurator.configure do |config|
  # Add :deploy method to ExampleGroups
  config.extend(TorqueSpec)
end

if ENV['TORQUEBOX_APP_NAME']
  module TorqueSpec
    def deploy(*descriptors)
      puts "JC: does nothing"
    end
  end
else
  TorqueSpec::Configurator.configure do |config|
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
end

require 'drb'
module TorqueSpec
  module ObjectExtensions
    def remote_describe(*args, &example_group_block)
      group = describe(*args, &example_group_block)
      unless ENV['TORQUEBOX_APP_NAME']
        class << group
          alias_method :original_run_examples, :run_examples
          def run_examples(reporter)
            begin
              DRb.start_service("druby://localhost:0")
            rescue SocketError, Errno::EADDRNOTAVAIL
              DRb.start_service("druby://:0")
            end
            daemon = DRbObject.new_with_uri("druby://127.0.0.1:7772")
            daemon.run( name, reporter.extend(DRbUndumped) )
            puts "JC: self=#{self.name} superclass=#{superclass.name}"
            DRb.stop_service
            # original_run_examples(reporter)
          end
          def children
            []                  # we have no nested groups locally, only remotely
          end
        end
      end
      group
    end
  end
end

class Object
  include TorqueSpec::ObjectExtensions
end

module TorqueSpec
  def self.rubylib
    Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "../../..", "*{spec,json,diff-lcs}*/lib"))).join(":")
  end
end
