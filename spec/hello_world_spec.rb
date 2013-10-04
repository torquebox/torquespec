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

require 'torquespec'
require 'open-uri'

TorqueSpec.lazy = false

describe "simple knob deployment" do
  
  deploy { File.join( File.dirname(__FILE__), "../apps/simple.knob" ) }

  it "should greet the world" do
    response = open("http://localhost:8080") {|f| f.read}
    response.strip.should == "Hello World!"
  end
end

describe "simple directory deployment" do
  
  deploy <<-DD_END.gsub(/^ {4}/,'')
    application:
      root: #{File.dirname(__FILE__)}/../apps/simple
  DD_END

  it "should greet the world" do
    response = open("http://localhost:8080") {|f| f.read}
    response.strip.should == "Hello World!"
  end
end

describe "war deployment" do
  
  deploy File.join( File.dirname(__FILE__), "../apps/node-info.war" )

  it "should greet the world" do
    response = open("http://localhost:8080/node-info") {|f| f.read}
    response.should include( 'JBoss-Cloud node info' )
  end
end

describe "missing knob handling" do
  
  it "should toss an error for a missing descriptor" do
    server = TorqueSpec::Server.new
    lambda {
      server.deploy "this-file-does-not-exist.yml"
    }.should raise_error
  end

end

