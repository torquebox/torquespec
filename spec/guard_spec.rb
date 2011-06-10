require 'torquespec'

remote_describe "remote guard test" do

  it "should work" do
    TorqueSpec.remote { true }.should be_true
    TorqueSpec.local { true }.should be_false
  end

end

describe "local guard test" do

  it "should work" do
    TorqueSpec.remote { true }.should be_false
    TorqueSpec.local { true }.should be_true
  end

end

