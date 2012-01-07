require 'spec_helper'

describe HTTParrot::ResponseFactory do 

  context "API" do 
    specify{ described_class.should respond_to(:clear!) }
    specify{ described_class.should respond_to(:define) }
    specify{ described_class.should respond_to(:build) }
    specify{ described_class.should respond_to(:one_of) }
    specify{ described_class.should respond_to(:collection_of) }
  end

  context "#define" do 
    before(:each) { HTTParrot::ResponseFactory.clear! }

    it "adds a factory to the factories available" do
      HTTParrot::ResponseFactory.define(:response) { |r| r.test = "Test" }
      HTTParrot::ResponseFactory.instance_variable_get("@factory_classes").size.should eq(1)
    end

    it "overwrites a factory with the same name" do
      HTTParrot::ResponseFactory.should_receive(:warn).with(/redefinition/)
      HTTParrot::ResponseFactory.define(:response) { |r| r.test = "Test1" }
      HTTParrot::ResponseFactory.define(:response) { |r| r.test = "Test2" }
      HTTParrot::ResponseFactory.instance_variable_get("@factory_classes").size.should eq(1)
    end

    it "warns when a factory is overwritten" do
      HTTParrot::ResponseFactory.should_receive(:warn).with(/redefinition/)
      HTTParrot::ResponseFactory.define(:response) { |r| r.test = "Test1" }
      HTTParrot::ResponseFactory.define(:response) { |r| r.test = "Test2" }
    end

    it "requires a block to be sent during definition" do 
      lambda{ HTTParrot::ResponseFactory.define(:response) }.should raise_error(/block/)
    end

    it "requires a factory name to be included" do 
      lambda{ HTTParrot::ResponseFactory.define { nil } }.should raise_error(/arguments/)
    end

  end

  context "#one_of" do

    it "requires choices to be provided" do
      expect{ HTTParrot::ResponseFactory.one_of([]) }.to raise_error
    end

  end

  context "#build" do
    before(:each) { HTTParrot::ResponseFactory.clear! }

    it "raises error if factory does not exist" do 
      expect{ HTTParrot::ResponseFactory.build(:response) }.to raise_error(/factory type/)
    end

  end
  
end
