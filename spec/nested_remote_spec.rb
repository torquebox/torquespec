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
require 'torquebox-core'

require 'jruby'
JRuby.objectspace = true

describe "out of the container" do

  deploy <<-END.gsub(/^ {4}/,'')
    application:
      root: #{File.dirname(__FILE__)}/../apps/simple
  END

  it "should still greet the world" do
    response = open("http://localhost:8080") {|f| f.read}
    response.strip.should == "Hello World!"
  end

  def blocks
    @blocks ||= []
  end

  before(:each) do
    blocks.push :anything
  end

  after(:each) do
    blocks.pop
    blocks.should be_empty
  end

  remote_describe "in container of the same deployed app" do
    include TorqueBox::Injectors

    before(:each) do
      blocks.push :anything
    end

    after(:each) do
      blocks.pop
      blocks.size.should == 1
    end

    it "remote? should work" do
      TorqueSpec.remote{true}.should be_true
      TorqueSpec.local{true}.should be_false
    end

    it "injection should work" do
      __inject__( 'service-registry' ).should_not be_nil
    end
  end

end

