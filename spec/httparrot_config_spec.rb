require 'spec_helper'

describe HTTParrot::Config do 

  context "config" do 

    context "defaults" do 
      specify{ HTTParrot::Config.Port.should eq(4000) }
      specify{ HTTParrot::Config.SSLPort.should eq(4001) }
      specify{ HTTParrot::Config.ssl.should be_true }
      specify{ HTTParrot::Config.template_root.should be_nil }
      specify{ HTTParrot::Config.verbose.should be_false }
    end

    it "updates :Port" do
      HTTParrot::Config.Port = 5000
      HTTParrot::Config.Port.should eq(5000)
      HTTParrot::Config.config[:Port].should eq(5000)

      HTTParrot::Config.restore_defaults
    end

    it "updates :SSLPort" do
      HTTParrot::Config.SSLPort = 5000
      HTTParrot::Config.SSLPort.should eq(5000)
      HTTParrot::Config.config[:SSLPort].should eq(5000)

      HTTParrot::Config.restore_defaults
    end

    it "updates :ssl" do
      HTTParrot::Config.ssl = false 
      HTTParrot::Config.ssl.should be_false 
      HTTParrot::Config.config[:ssl].should be_false 

      HTTParrot::Config.restore_defaults
    end

    it "updates :verbose" do
      HTTParrot::Config.verbose = true 
      HTTParrot::Config.verbose.should be_true
      HTTParrot::Config.config[:verbose].should be_true

      HTTParrot::Config.restore_defaults
    end

    it "updates :template_root" do
      HTTParrot::Config.template_root = "updated value" 
      HTTParrot::Config.template_root.should eq("updated value") 
      HTTParrot::Config.config[:template_root].should eq("updated value") 

      HTTParrot::Config.restore_defaults
    end

  end

end
