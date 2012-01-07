require 'spec_helper'

describe HTTParrot::ResponseFactory do 

  context "API" do 
    specify{ described_class.should respond_to(:clear!) }
    specify{ described_class.should respond_to(:define) }
    specify{ described_class.should respond_to(:build) }
    specify{ described_class.should respond_to(:one_of) }
    specify{ described_class.should respond_to(:collection_of) }
  end

  context "#clear!" do

    it "removes all factories when cleared" do
      HTTParrot::ResponseFactory.define(:response) { |r| r.test = "Test" }
      HTTParrot::ResponseFactory.clear!
      HTTParrot::ResponseFactory.clear!
      HTTParrot::ResponseFactory.instance_variable_get("@factory_classes").size.should eq(0)
    end

  end

  context "#collection_of" do
    before(:each) { HTTParrot::ResponseFactory.clear! }

    it "requires the factory_class to exist" do 
      expect{ HTTParrot::ResponseFactory.collection_of(:response, 10) }.to raise_error(/factory/)
    end

    it "returns the specified number of Widgets" do 
      HTTParrot::ResponseFactory.define(:response) { |t| t.value = "Test" }
      c = HTTParrot::ResponseFactory.collection_of(:response, 10)
      c.size.should eq(10)
    end

    it "returns Widgets with values from factory definitions" do
      HTTParrot::ResponseFactory.define(:response) { |t| t.value = "Test" }
      c = HTTParrot::ResponseFactory.collection_of(:response, 10)
      c.each do |w|
        w.should be_a(HTTParrot::Widget)
        w.value.should eq("Test")
      end
    end

    it "returns Widgets with values from factory definitions overridden" do
      HTTParrot::ResponseFactory.define(:response) { |t| t.value = "Test" }
      c = HTTParrot::ResponseFactory.collection_of(:response, 10, :value => "Over")
      c.each do |w|
        w.should be_a(HTTParrot::Widget)
        w.value.should eq("Over")
      end
    end

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

    it "warns if choices are not provided" do
      HTTParrot::ResponseFactory.should_receive(:warn).with(/choices/)
      HTTParrot::ResponseFactory.one_of([])
    end

    it "returns a choice" do 
      choices = [1, 2, 3, 4, 5]
      choices.should include(HTTParrot::ResponseFactory.one_of(choices))
      choices = ["choice1", "choice2", "choice3"]
      choices.should include(HTTParrot::ResponseFactory.one_of(choices))
    end

  end

  context "#build" do
    before(:each) { HTTParrot::ResponseFactory.clear! }

    it "raises error if factory does not exist" do 
      expect{ HTTParrot::ResponseFactory.build(:response) }.to raise_error(/factory type/)
    end

    it "calls the definition block during build" do 
      HTTParrot::ResponseFactory.define(:response) { |r| raise "block call" }
      expect{ HTTParrot::ResponseFactory.build(:response) }.to raise_error(/block call/)
    end

    it "returns a response with values set from definition" do 
      HTTParrot::ResponseFactory.define(:response) { |r| r.value = "Test1" }
      res = HTTParrot::ResponseFactory.build(:response)
      res.value.should eq("Test1")
    end

    it "returns a Widget" do 
      HTTParrot::ResponseFactory.define(:response) { |r| r.value = "Test1" }
      res = HTTParrot::ResponseFactory.build(:response)
      res.should be_a(HTTParrot::Widget)
    end

    it "overrides defaults when changes are provided in build" do 
      HTTParrot::ResponseFactory.define(:response) { |r| r.value = "Test1" }
      res = HTTParrot::ResponseFactory.build(:response, :value => "New Val")
      res.value.should eq("New Val")
    end

  end
  
end
