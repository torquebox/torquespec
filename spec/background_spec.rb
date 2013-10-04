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
require 'torquebox-messaging'


describe "simple backgrounding" do
  
  deploy <<-DD_END.gsub(/^ {4}/,'')
    application:
      root: #{File.dirname(__FILE__)}/../apps/background
  DD_END

  it "should respond by spawning a background task" do
    response = open("http://localhost:8080") {|f| f.read}
    response.strip.should == "success"
    TorqueBox::Messaging::Queue.new('/queue/background').publish('release')
    TorqueBox::Messaging::Queue.new('/queue/foreground').receive(:timeout => 5000).should == 'success'
  end

end

