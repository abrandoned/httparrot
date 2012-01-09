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

  specify{ subject.to_hash.should be_a(Hash) }

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

    it "overwrites existing values" do
      current = HTTParrot::Widget.new(:first => 1, :second => 2)
      current.parent!({:first => 2, :second => 1})
      current.first.should eq(2)
      current.second.should eq(1)
    end

    it "overwrites with last parent call for adding values" do 
      current = HTTParrot::Widget.new
      current.parent!(:first => 1)
      current.parent!(:second => 2)
      current.parent!(:third => 3)
      current.parent!(:first => 2, :second => 3, :third => 1)
      current.first.should eq(2)
      current.second.should eq(3)
      current.third.should eq(1)
    end

  end

  context "#rack_response" do 
    before(:each) { HTTParrot::Config.restore_defaults! }

    it "returns a valid rack response" do 
      current = described_class.new
      HTTParrot::Config.config[:template_root] = File.dirname(__FILE__) + "/templates" 
      current.rack_response.should be_a(Array)
      current.rack_response.size.should eq(3)
      current.rack_response.first.should be_a(Integer)
      current.rack_response.last.should respond_to(:each)
      current.rack_response[1].should be_a(Hash)
    end

  end

  context "#to_s" do
    before(:each) { HTTParrot::Config.restore_defaults! }

    it "renders the file when full path is present in template_file" do 
      current = described_class.new
      current.template_file = File.expand_path("./templates/awesometown_protocol.erb",
                                               File.dirname(__FILE__))

      current.to_s.should match(/AWESOMEHEADER/i)
    end

    it "prioritizes template_file over HTTParrot::Config.template_root" do 
      current = described_class.new
      current.template_file = File.expand_path("./templates/awesometown_protocol.erb",
                                               File.dirname(__FILE__))

      current.to_s.should match(/AWESOMEHEADER/i)
    end

    context "rendering erb with current widget" do
      before(:each) { HTTParrot::ResponseFactory.clear! }

      it "inserts the value of defined methods into the output" do
        current = described_class.new
        current.widget_header = "TEST HEADER"
        HTTParrot::Config.config[:template_root] = File.dirname(__FILE__) + "/templates" 
        current.to_s.should match(/TEST HEADER/)
      end

      it "removes erb tags when value is not present" do 
        current = described_class.new
        HTTParrot::Config.config[:template_root] = File.dirname(__FILE__) + "/templates" 
        current.to_s.should_not match(/widget_header/)
      end

    end

    context "falls back to HTTParrot::Config[:template_root] when no template_file" do
      before(:each) { HTTParrot::Config.restore_defaults! }

      it "warn" do
        current = described_class.new
        bad_dir = File.expand_path("../lib/httparrot.rb", File.dirname(__FILE__))
        HTTParrot::Config.config[:template_root] = File.dirname(bad_dir) 
        warning = Regexp.escape(current.__send__(:template_root_search))
        current.should_receive(:warn).with(/#{warning}/)
        current.to_s
      end

      it "success" do
        current = described_class.new
        HTTParrot::Config.config[:template_root] = File.dirname(__FILE__) + "/templates" 
        current.to_s.should match(/WIDGETHEADER/i)
      end

      it "success, handles trailing slash" do 
        current = described_class.new
        HTTParrot::Config.config[:template_root] = File.dirname(__FILE__) + "/templates/"
        current.to_s.should match(/WIDGETHEADER/i)
      end

    end

  end

end
