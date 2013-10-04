# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
      yaml = YAML.load_file( path )
      if yaml.is_a? Hash
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
        File.open( path, 'w' ) do |file|
          YAML.dump( yaml, file )
        end
      end
      path
    rescue Exception
      path
    end
  end

end

