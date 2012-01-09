require 'spec_helper'

describe HTTParrot::Config do 

  context "defaults" do 
    before(:each){ HTTParrot::Config.restore_defaults! }

    specify{ HTTParrot::Config.Port.should eq(4000) }
    specify{ HTTParrot::Config.SSLPort.should eq(4001) }
    specify{ HTTParrot::Config.ssl.should be_true }
    specify{ HTTParrot::Config.template_root.should be_nil }
    specify{ HTTParrot::Config.verbose.should be_false }
  end

  context "updates" do
    before(:each) { HTTParrot::Config.restore_defaults! }

    it ":Port" do
      HTTParrot::Config.Port = 5000
      HTTParrot::Config.Port.should eq(5000)
      HTTParrot::Config.config[:Port].should eq(5000)
    end

    it ":SSLPort" do
      HTTParrot::Config.SSLPort = 5000
      HTTParrot::Config.SSLPort.should eq(5000)
      HTTParrot::Config.config[:SSLPort].should eq(5000)
    end

    it ":ssl" do
      HTTParrot::Config.ssl = false 
      HTTParrot::Config.ssl.should be_false 
      HTTParrot::Config.config[:ssl].should be_false 
    end

    it ":verbose" do
      HTTParrot::Config.verbose = true 
      HTTParrot::Config.verbose.should be_true
      HTTParrot::Config.config[:verbose].should be_true
    end

    it ":template_root" do
      HTTParrot::Config.template_root = "updated value" 
      HTTParrot::Config.template_root.should eq("updated value") 
      HTTParrot::Config.config[:template_root].should eq("updated value") 
    end

  end

end
