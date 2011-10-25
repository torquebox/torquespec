require 'pathname'
require 'fileutils'
require 'yaml'

module TorqueSpec

  class DeploymentDescriptor
    def initialize(descriptor, name, daemonify = false)
      @descriptor = descriptor
      @path = Pathname.new( name.gsub(/\W/,'_') + "-knob.yml" ).expand_path( TorqueSpec.knob_root )
      @daemonify = daemonify
      FileUtils.mkdir_p(TorqueSpec.knob_root) unless File.exist?(TorqueSpec.knob_root)
    end
    def path
      verify( hash || filename || heredoc )
    end
    def hash
      if @descriptor.is_a? Hash
        File.open( @path, 'w' ) do |file|
          YAML.dump( stringify_keys(@descriptor), file )
        end
        @path.to_s
      end
    end
    def filename
      filename = Pathname.new(@descriptor).expand_path( TorqueSpec.knob_root )
      if filename.exist?
        filename.to_s
      end
    end
    def heredoc
      File.open( @path, 'w' ) do |file|
        file.write(@descriptor)
      end
      @path.to_s
    end
    def stringify_keys(x)
      x.is_a?(Hash) ? x.inject({}) {|h,(k,v)| h[k.to_s] = stringify_keys(v); h} : x
    end

    def verify( path )
      original = YAML.load_file( path )
      if original.is_a? Hash
        yaml = original.dup
        if @daemonify
          yaml['application'] ||= {}
          yaml['application']['root'] ||= TorqueSpec.app_root
          yaml['services'] ||= {}
          yaml['services'].update( 'TorqueSpec::Daemon' => { 'argv' => TorqueSpec.argv, 'pwd' => Dir.pwd, 'spec_dir' => TorqueSpec.spec_dir } )
          yaml['environment'] ||= {}
          env = { 'RUBYLIB' => TorqueSpec.rubylib }
          yaml['environment'].update(env) {|k,oldval,newval| "#{oldval}:#{newval}"}
        end
        yaml['ruby'] ||= {}
        yaml['ruby']['version'] ||= RUBY_VERSION[0,3]
        # yaml['ruby']['compile_mode'] ||= 'off'
        if original != yaml
          File.open( path, 'w' ) do |file|
            YAML.dump( yaml, file )
          end
        end
      end
      path
    rescue Exception
      path
    end
  end

end

