require 'torquespec'
require 'rspec/core'
require 'drb'

module TorqueSpec
  class Daemon

    def initialize(opts={})
      puts "JC: create daemon opts=#{opts.inspect}"
      dir = opts['pwd'].to_s
      raise "The 'pwd' option must contain a valid directory name" unless dir.any? && File.exist?(dir)
      Dir.chdir( dir ) do
        RSpec::Core::Runner.disable_autorun! # avoid a bunch of at_exit finalizer errors
        @options = RSpec::Core::ConfigurationOptions.new( opts['argv'].to_a )
        @options.parse_options

        @configuration = RSpec::configuration
        @world         = RSpec::world

        @options.configure(@configuration)
        @configuration.load_spec_files
        @configuration.configure_mock_framework
        @configuration.configure_expectation_framework
      end
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

      def run(reporter)
        begin
          eval_before_alls(new)
          run_remotely(reporter)
        ensure
          eval_after_alls(new)
        end
      end

      # Delegate all examples (and nested groups) to remote daemon
      def run_remotely(reporter)
        DRb.start_service("druby://127.0.0.1:0")
        daemon = DRbObject.new_with_uri("druby://127.0.0.1:#{TorqueSpec.drb_port}")
        # TODO: maybe fall back to local if can't run?
        begin
          daemon.run( name, reporter )
        rescue Exception
          puts $!, $@
        ensure
          DRb.stop_service
        end
      end

    end
  end
end

module RSpec
  module Core
    class Example
      def marshal_dump
        @metadata
      end
      def marshal_load metadata
        @metadata = metadata
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
end
