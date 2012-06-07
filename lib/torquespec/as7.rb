require 'rubygems'
require 'json'
require 'uri'

module TorqueSpec
  module AS7

    def port
      9990
    end

    def start_command
      "\"#{TorqueSpec.java_home}/bin/java\" #{TorqueSpec.jvm_args} -Dorg.jboss.resolver.warning=true -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Dorg.jboss.boot.log.file=\"#{TorqueSpec.jboss_home}/standalone/log/boot.log\" -Dlogging.configuration=file:\"#{TorqueSpec.jboss_home}/standalone/configuration/logging.properties\" -jar \"#{TorqueSpec.jboss_home}/jboss-modules.jar\" -mp \"#{TorqueSpec.jboss_home}/modules\" -jaxpmodule javax.xml.jaxp-provider org.jboss.as.standalone -Djboss.home.dir=\"#{TorqueSpec.jboss_home}\""
    end

    def shutdown
      api( :operation => "shutdown" )
    rescue EOFError
      # ignorable
    end

    def deployed?(path)
      response = JSON.parse(api(:operation => "read-children-names", "child-type" => "deployment"))
      response['result'].include? addressify(path)
    end
    
    def _deploy(path)
      _undeploy(path) if deployed?(path)
      api( :operation => "add",
           :address   => [{ :deployment => addressify(path) }],
           :content   => [{ :url => urlify(path) }] )
      api( :operation => "deploy",
           :address   => [{ :deployment => addressify(path) }] )
    end

    def _undeploy(path)
      api( :operation => "remove",
           :address   => [{ "deployment" => addressify(path) }] )
    end

    def ready?
      response = JSON.parse( api( :operation => "read-attribute",
                                  :name      => "server-state") )
      response['outcome'].downcase=='success' && response['result'].downcase=='running'
    rescue
      false
    end

    private

    def api(params)
      post('/management', params.merge('json.pretty' => 1).to_json)
    end

    def urlify(path)
      uri = URI.parse(path)
      uri.scheme.nil? || uri.scheme =~ /^[a-zA-Z]$/ ? "file:#{path}" : path
    end
    
    def addressify(path)
      File.basename(path)
    end
  end

  module Domain

    def host_controller
      JSON.parse(api(:operation => "read-children-resources", "child-type" => "host"))['result'].first
    end
    
    def server_group
      @server_group ||= JSON.parse(api(:operation => "read-children-names", "child-type" => "server-group"))['result'].first
    end

    def start_command
      "\"#{TorqueSpec.java_home}/bin/java\" -D\"[Process Controller]\" #{TorqueSpec.jvm_args} -Djava.net.preferIPv4Stack=true -Dorg.jboss.resolver.warning=true -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Djboss.modules.system.pkgs=org.jboss.byteman -Djava.awt.headless=true -Djboss.domain.default.config=domain.xml -Djboss.host.default.config=host.xml -Dorg.jboss.boot.log.file=\"#{TorqueSpec.jboss_home}/domain/log/process-controller.log\" -Dlogging.configuration=\"file:#{TorqueSpec.jboss_home}/domain/configuration/logging.properties\" -jar \"#{TorqueSpec.jboss_home}/jboss-modules.jar\" -mp \"#{TorqueSpec.jboss_home}/modules\" org.jboss.as.process-controller -jboss-home \"#{TorqueSpec.jboss_home}\" -jvm \"#{TorqueSpec.java_home}/bin/java\" -mp \"#{TorqueSpec.jboss_home}/modules\" -- -Dorg.jboss.boot.log.file=\"#{TorqueSpec.jboss_home}/domain/log/host-controller.log\" -Dlogging.configuration=\"file:#{TorqueSpec.jboss_home}/domain/configuration/logging.properties\" #{TorqueSpec.jvm_args} -Djava.net.preferIPv4Stack=true -Dorg.jboss.resolver.warning=true -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Djboss.modules.system.pkgs=org.jboss.byteman -Djava.awt.headless=true -Djboss.domain.default.config=domain.xml -Djboss.host.default.config=host.xml -- -default-jvm \"#{TorqueSpec.java_home}/bin/java\""
    end
    
    def ready?
      host = host_controller[1]
      host["server-config"] == host["server"]
    rescue
      false
    end

    def _deploy(path)
      _undeploy(path) if deployed?(path)
      api( :operation => "add",
           :address   => [{ :deployment => addressify(path) }],
           :content   => [{ :url => urlify(path) }] )
      api( :operation => "add",
           :address   => [{"server-group" => server_group}, {:deployment => addressify(path)}],
           :content   => [{ :url => urlify(path) }] )
      api( :operation => "deploy",
           :address   => [{"server-group" => server_group}, {:deployment => addressify(path)}] )
    end

    def _undeploy(path)
      api( :operation => "remove",
           :address   => [{"server-group" => server_group}, {:deployment => addressify(path)}] )
      api( :operation => "remove",
           :address   => [{"deployment" => addressify(path)}] )
    end

    def shutdown
      api( :operation => "shutdown", :address => [ "host", host_controller[0] ] )
    rescue EOFError
      # ignorable
    end

  end
end
