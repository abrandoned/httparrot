require 'spec_helper'

describe HTTParrot::Widget do

  context "API" do 
    specify{ subject.should respond_to(:rack_response) }
    specify{ subject.should respond_to(:to_hash) }
    specify{ subject.should respond_to(:to_rack) }
    specify{ subject.should respond_to(:to_rack_response) }
    specify{ subject.should respond_to(:parent) }
    specify{ subject.should respond_to(:parent!) }
  end

  shared_examples "a parental relationship" do |meth|

    it "adds new values" do 
      current = HTTParrot::Widget.new(:first => 1, :second => 2)
      current.method(meth).call({:first => 2, :second => 1, :third => 3})
      current.third.should eq(3)
    end

    it "raises error when not a symbol or respond_to? to_hash" do 
      expect{ subject.method(meth).call([]) }.to raise_error(/symbol/) 
    end

    it "raises error when parent factory does not exist" do 
      expect{ subject.method(meth).call(:something) }.to raise_error(/unknown factory/i)
    end

    it "builds corresponding factory when symbol" do 
      HTTParrot::ResponseFactory.define(:response) { |r| r.value = "Test" }
      current = HTTParrot::Widget.new
      current.method(meth).call(:response)
      current.value.should eq("Test")
    end

    it "adds values from multiple parents" do 
      current = HTTParrot::Widget.new
      current.method(meth).call(:first => 1)
      current.method(meth).call(:second => 2)
      current.method(meth).call(:third => 3)
      current.first.should eq(1)
      current.second.should eq(2)
      current.third.should eq(3)
    end

  end

  context "#parent" do
    before(:each) { HTTParrot::ResponseFactory.clear! }

    it_behaves_like "a parental relationship", :parent

    it "does not overwrite existing values" do
      current = HTTParrot::Widget.new(:first => 1, :second => 2)
      current.parent({:first => 2, :second => 1})
      current.first.should eq(1)
      current.second.should eq(2)
    end

    it "respects parent call order for adding values" do 
      current = HTTParrot::Widget.new
      current.parent(:first => 1)
      current.parent(:second => 2)
      current.parent(:third => 3)
      current.parent(:first => 2, :second => 3, :third => 1)
      current.first.should eq(1)
      current.second.should eq(2)
      current.third.should eq(3)
    end

  end

  context "#parent!" do 
    before(:each) { HTTParrot::ResponseFactory.clear! }

    it_behaves_like "a parental relationship", :parent!

  end

  context "#rack_response" do 

    it "warns if no template_file is defined" do 
      subject.should_receive(:warn).with(/template_file/)
      subject.rack_response
    end

  end

  context "#to_s" do
    
    it "warns if no template_file is defined" do 
      subject.should_receive(:warn).with(/template_file/)
      subject.to_s
    end

  end

end
