require 'torquespec/deployment_descriptor'

module TorqueSpec

  # Accepts any combination of hashes, filenames, or heredocs
  def deploy(*descriptors)
    metaclass = class << self; self; end
    metaclass.send(:define_method, :deploy_paths) do
      FileUtils.mkdir_p(TorqueSpec.knob_root) unless File.exist?(TorqueSpec.knob_root)
      descriptors.map do |descriptor| 
        DeploymentDescriptor.new(descriptor, self.display_name).path
      end
    end
  end

  class << self
    attr_accessor :host, :port, :knob_root, :jboss_home, :jboss_conf, :jvm_args, :max_heap, :lazy
    def configure
      yield self
    end
    def jvm_args
      max_heap ? @jvm_args.sub(/-Xmx\w+/, "-Xmx#{max_heap}") : @jvm_args
    end
  end

end

# Default TorqueSpec options
TorqueSpec.configure do |config|
  config.knob_root = ".torquespec"
  config.lazy = false
  config.host = 'localhost'
  config.port = 8080
  config.jboss_home = ENV['JBOSS_HOME']
  config.jboss_conf = 'default'
  config.jvm_args = "-Xmx1024m -XX:MaxPermSize=512m -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -Djruby_home.env.ignore=true -Dgem.path=default"
end

