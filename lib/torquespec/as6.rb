module TorqueSpec
  module AS6

    def port
      8080
    end

    def start_command
      "#{TorqueSpec.java_home}/bin/java -cp #{TorqueSpec.jboss_home}/bin/run.jar #{TorqueSpec.jvm_args} -Djava.endorsed.dirs=#{TorqueSpec.jboss_home}/lib/endorsed org.jboss.Main"
    end

    def shutdown
      success?( jmx_console( :action     => 'invokeOpByName', 
                             :name       => 'jboss.system:type=Server', 
                             :methodName => 'shutdown' ) )
    end

    def ready?
      response = jmx_console( :action => 'inspectMBean', 
                              :name   => 'jboss.system:type=Server' )
      "True" == response.match(/>Started<.*?<pre>\s+^(\w+)/m)[1]
    rescue
      false
    end

    def _deploy(url)
      success?( deployer( 'redeploy', url ) )
    end

    def _undeploy(url)
      success?( deployer( 'undeploy', url ) )
    end



    private

    def success?(response)
      response.include?( "Operation completed successfully" )
    end

    def deployer(method, url)
      jmx_console( :action     => 'invokeOpByName', 
                   :name       => 'jboss.system:service=MainDeployer', 
                   :methodName => method,
                   :argType    => 'java.net.URL', 
                   :arg0       => url )
    end

    def jmx_console(params)
      post('/jmx-console/HtmlAdaptor', params)
    end

  end
end
