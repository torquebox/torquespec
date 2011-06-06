require 'rspec/core'
require 'drb'
require 'torquebox/torquebox'

module TorqueSpec
  class Daemon

    def initialize(opts={})
      puts "JC: create daemon opts=#{opts}"
      @argv = opts['argv'].to_a

      @options = RSpec::Core::ConfigurationOptions.new(@argv)
      @options.parse_options

      @configuration = RSpec::configuration
      @world         = RSpec::world

      @options.configure(@configuration)
      @configuration.load_spec_files
      @configuration.configure_mock_framework
      @configuration.configure_expectation_framework
    end

    def start
      puts "JC: start daemon"
      DRb.start_service("druby://127.0.0.1:#{TorqueSpec.drb_port}", self)
    end

    def stop
      puts "JC: stop daemon"
      DRb.stop_service
    end

    def run(name, reporter)
      puts "JC: run #{name}"
      example_group = @world.example_groups.find { |g| g.name == name }
      example_group.run( reporter )
    end

    # Intended to extend an RSpec::Core::ExampleGroup
    module Client
      # Delegate all examples (and nested groups) to remote daemon
      def run_examples(reporter)
        DRb.start_service("druby://127.0.0.1:0")
        daemon = DRbObject.new_with_uri("druby://127.0.0.1:#{TorqueSpec.drb_port}")
        begin
          daemon.run( name, reporter )
        rescue Exception
          puts $!, $@
        ensure
          DRb.stop_service
        end
      end
      # We have no nested groups locally, only remotely
      def children
        []
      end
    end
  end
end

# We don't actually serialize Proc objects, but we prevent a TypeError
# when an object containing a Proc is serialized, e.g. when an Example
# is passed to a remote Reporter.  This works for us because the
# Reporter doesn't use the Example's Proc objects.
class Proc
  def marshal_dump
  end
  def marshal_load *args
  end
  def _dump *args
  end
  def self._load *args
    new {}
  end
end
