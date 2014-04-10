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

begin
  # RSpec v2
  require 'rspec'
  TorqueSpec::Configurator = RSpec
rescue Exception
  # RSpec v1
  require 'spec'
  TorqueSpec::Configurator = Spec::Runner
end

TorqueSpec::Configurator.configure do |config|
  # Add :deploy method to ExampleGroups
  config.extend(TorqueSpec)
end

TorqueSpec.remote {
  module TorqueSpec
    def deploy(*descriptors)
    end
  end
}

TorqueSpec.local {

  require 'torquespec/server'

  default_desc = nil
  if dpath = File.join(TorqueSpec.knob_root, TorqueSpec.default_deploy)
    if File.exist?(dpath)
      default_desc = TorqueSpec::DeploymentDescriptor.new(File.open(dpath).read, "default_deploy", false).path
    end
  end

  TorqueSpec::Configurator.configure do |config|
    config.before(:suite) do
      Thread.current[:app_server] = TorqueSpec::Server.new
      Thread.current[:app_server].start(:wait => 120)
      Thread.current[:app_server].deploy(default_desc) if default_desc
    end
    
    config.before(:all) do
      if self.class.respond_to?( :deploy_paths )
        Thread.current[:app_server].undeploy(default_desc) if default_desc && self.class.deploy_paths.size > 0
        self.class.deploy_paths.each do |path|
          Thread.current[:app_server].deploy(path)
        end
      end
    end

    config.after(:all) do
      if self.class.respond_to?( :deploy_paths )
        self.class.deploy_paths.each do |path|
          Thread.current[:app_server].undeploy(path)
        end 
        Thread.current[:app_server].deploy(default_desc) if default_desc && self.class.deploy_paths.size > 0 
      end
    end

    config.after(:suite) do
      Thread.current[:app_server].stop
    end
  end
}

require 'torquespec/daemon'

module TorqueSpec
  module ObjectExtensions
    def remote_describe(*args, &example_group_block)
      unless TorqueSpec.domain_mode
        group = describe(*args, &example_group_block)
        TorqueSpec.remote? ? group : group.extend( TorqueSpec::Daemon::Client )
      end
    end
  end
end

class Object
  include TorqueSpec::ObjectExtensions
end
