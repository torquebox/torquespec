require 'pathname'

module TorqueSpec

  def deploy(*paths)
    metaclass = class << self; self; end
    metaclass.send(:define_method, :deploy_paths) do
      paths.map {|p| Pathname.new(p).absolute? ? p : File.join(TorqueSpec.knob_root, p) }
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
  config.lazy = true
  config.host = 'localhost'
  config.port = 8080
  config.jboss_home = ENV['JBOSS_HOME']
  config.jboss_conf = 'default'
  config.jvm_args = "-Xmx1024m -XX:MaxPermSize=512m -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -Djruby_home.env.ignore=true -Dgem.path=default"
end

