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

  before(:each) do
    puts "JC: before local"
  end

  after(:each) do
    puts "JC: after local"
  end

  remote_describe "in container of the same deployed app" do
    include TorqueBox::Injectors

    before(:each) do
      puts "JC: before remote"
    end

    after(:each) do
      puts "JC: after remote"
    end

    it "remote? should work" do
      TorqueSpec.remote{true}.should be_true
      TorqueSpec.local{true}.should be_false
    end

    it "injection should work" do
      inject( 'service-registry' ).should_not be_nil
    end
  end

end

