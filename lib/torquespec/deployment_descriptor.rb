require 'pathname'
require 'fileutils'
require 'yaml'

module TorqueSpec

  class DeploymentDescriptor
    def initialize(descriptor, name, daemonify = false)
      @descriptor = descriptor
      @path = Pathname.new( name.gsub(/\W/,'_') + "-knob.yml" ).expand_path( TorqueSpec.knob_root )
      @daemonify = daemonify
    end
    def path
      daemonify( hash || filename || heredoc )
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

    def daemonify( path )
      if @daemonify
        yaml = YAML.load_file( path )
        if yaml.is_a? Hash
          yaml['services'] ||= {}
          yaml['services'].update( 'TorqueSpec::Daemon' => { 'argv' => TorqueSpec.argv, 'pwd' => Dir.pwd } )
          yaml['environment'] ||= {}
          env = { 'RUBYLIB' => TorqueSpec.rubylib }
          yaml['environment'].update(env) {|k,oldval,newval| "#{oldval}:#{newval}"}
          File.open( path, 'w' ) do |file|
            YAML.dump( yaml, file )
          end
        else
          $stderr.puts "WARN: Unable to decorate your deployment descriptor with TorqueSpec::Daemon"
        end
      end
      path
    end
  end

end

