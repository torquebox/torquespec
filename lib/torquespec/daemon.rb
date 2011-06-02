require 'rspec/core'
require 'drb'

module TorqueSpec
  class Daemon

    PORT = 7772

    def initialize(opts={})
      @argv = opts['argv'].to_a
      @port = opts['port'] || PORT

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
      DRb.start_service("druby://127.0.0.1:#{@port}", self)
    end

    def stop
      DRb.stop_service
    end

    def run(name, reporter)
      puts "JC: testing #{name}"
      example_group = @world.example_groups.find { |g| g.name == name }
      puts "JC: found #{example_group}"
      example_group.run( reporter )
    end
  end
end
