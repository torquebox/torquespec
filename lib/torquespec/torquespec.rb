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
    attr_accessor :knob_root, :jboss_home, :jvm_args, :max_heap, :lazy
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

end

# Default TorqueSpec options
TorqueSpec.configure do |config|
  config.knob_root = ".torquespec"
  config.jboss_home = ENV['JBOSS_HOME']
  config.jvm_args = "-Xms64m -Xmx1024m -XX:MaxPermSize=512m -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -Djruby_home.env.ignore=true -Dgem.path=default"
end

