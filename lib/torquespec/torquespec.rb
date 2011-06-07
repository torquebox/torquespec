require 'torquespec/deployment_descriptor'

module TorqueSpec

  # Accepts any combination of hashes, filenames, or heredocs
  def deploy(*descriptors, &block)
    metaclass = class << self; self; end
    metaclass.send(:define_method, :deploy_paths) do
      return @deploy_paths if @deploy_paths
      FileUtils.mkdir_p(TorqueSpec.knob_root) unless File.exist?(TorqueSpec.knob_root)
      descriptors << block.call if block
      i = descriptors.size > 1 ? 0 : nil
      @deploy_paths = descriptors.map do |descriptor| 
        DeploymentDescriptor.new(descriptor, "#{self.display_name}#{i&&i-=1}").path
      end
    end
  end

  class << self
    attr_accessor :knob_root, :jboss_home, :jvm_args, :max_heap, :lazy, :drb_port
    def configure
      yield self
    end
    def jvm_args
      max_heap ? @jvm_args.sub(/-Xmx\w+/, "-Xmx#{max_heap}") : @jvm_args
    end
    def as7?
      File.exist?( File.join( jboss_home, "bin/standalone.sh" ) )
    end
  end

  # A somewhat hackish way of exposing client-side gems to the server-side daemon
  def self.rubylib
    Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "../../..", "*{spec,diff-lcs}*/lib"))).join(":")
  end
  # The way client-side specs are passed to the daemon
  def self.specs
    RSpec::configuration.files_to_run.map {|f| File.expand_path(f) }.inspect
  end
end

# Default TorqueSpec options
TorqueSpec.configure do |config|
  config.drb_port = 7772
  config.knob_root = ".torquespec"
  config.jboss_home = ENV['JBOSS_HOME']
  config.jvm_args = "-Xms64m -Xmx1024m -XX:MaxPermSize=512m -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -Dgem.path=default"
end

