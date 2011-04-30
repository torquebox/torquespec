require 'pathname'
require 'fileutils'
require 'yaml'

module TorqueSpec

  class DeploymentDescriptor
    def initialize(descriptor, name)
      @descriptor = descriptor
      @path = Pathname.new( name.gsub(/\W/,'_') + "-knob.yml" ).expand_path( TorqueSpec.knob_root )
    end
    def path
      hash || filename || heredoc
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
  end

end

