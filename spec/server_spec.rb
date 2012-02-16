require 'spec_helper'
require 'net/http'

describe HTTParrot::Server do

  before(:all) do 
    @server = HTTParrot::Server.new
    @server.start
  end

  after(:all) do 
    @server.stop
  end

  context "API" do 
    specify{ @server.should respond_to(:start) }
    specify{ @server.should respond_to(:stop) }
    specify{ @server.should respond_to(:running?) }
    specify{ @server.should respond_to(:started?) }
    specify{ @server.should respond_to(:clear!) }
    specify{ @server.should respond_to(:reset_counts) }
    specify{ @server.should respond_to(:call) }
    specify{ @server.should respond_to(:register) }
  end 

  specify{ @server.running?.should be_true } 
  specify{ @server.started?.should be_true }

  context "#initialize" do 

    it "uses HTTParrot::Content defaults (by default)" do 
      current = described_class.new
      current.options.should include(HTTParrot::Config.config)
    end

    it "allows overrides from passed options" do 
      current = described_class.new(:Port => 6000)
      current.options[:Port].should eq(6000)
    end

  end

  context "#clear!" do 
    before(:each) do 
      HTTParrot::ResponseFactory.clear!
      HTTParrot::Config.config[:template_root] = File.dirname(__FILE__)
      HTTParrot::ResponseFactory.define(:widget) { |r| r.widget_header = "SERVER" }
    end

    it "resets all handlers" do
      handlers = @server.instance_variable_get("@call_handlers")
      handlers.each_value {|v| v.should be_empty }
      widget = HTTParrot::ResponseFactory.build(:widget)
      @server.register(:get, lambda{ |v| v =~ /widget/ }, widget.to_rack)
      @server.clear!
      handlers = @server.instance_variable_get("@call_handlers")
      handlers.each_value {|v| v.should be_empty }
    end

  end

  describe "counts and call handlers" do
    before(:each) do 
      HTTParrot::ResponseFactory.clear!
      HTTParrot::Config.config[:template_root] = File.dirname(__FILE__)
      HTTParrot::ResponseFactory.define(:widget) { |r| r.widget_header = "SERVER" }
      @widget = HTTParrot::ResponseFactory.build(:widget)
      @server.clear!
    end

    context "call_handlers" do 
      before(:each) do
        @widget_handler = @server.register(:post, lambda{ |v| v =~ /widget/ }, @widget.to_rack)
        http_request = Net::HTTP.new("127.0.0.1", HTTParrot::Config.Port)
        http_request.post("/widget", "widget=widget")
      end

      it "counts calls" do
        @widget_handler.response_count.should eq(1)
      end

      it "resets counts" do 
        @server.reset_counts
        @widget_handler.response_count.should eq(0)
      end

    end

    context "regex_handlers" do
      before(:each) do 
        @widget_handler = @server.register(:post, /widget/, @widget.to_rack)
        http_request = Net::HTTP.new("127.0.0.1", HTTParrot::Config.Port)
        http_request.post("/widget", "widget=widget")
      end

      it "counts calls" do
        @widget_handler.response_count.should eq(1)
      end

      it "resets counts" do 
        @server.reset_counts
        @widget_handler.response_count.should eq(0)
      end

    end

    context "endpoint_handlers" do 
      before(:each) do
        @widget_handler = @server.register(:post, "widget", @widget.to_rack)
        http_request = Net::HTTP.new("127.0.0.1", HTTParrot::Config.Port)
        http_request.post("/widget", "widget=widget")
      end

      it "counts calls" do
        @widget_handler.response_count.should eq(1)
      end

      it "resets counts" do 
        @server.reset_counts
        @widget_handler.response_count.should eq(0)
      end

    end

    context "complex_handlers" do 
      before(:each) do 
        @widget_handler = @server.register(:post, ["widget", /widget/], @widget.to_rack)
        http_request = Net::HTTP.new("127.0.0.1", HTTParrot::Config.Port)
        http_request.post("/widget", "widget=widget")
      end

      it "counts calls" do
        @widget_handler.response_count.should eq(1)
      end

      it "resets counts" do 
        @server.reset_counts
        @widget_handler.response_count.should eq(0)
      end

    end

  end

  context "#register" do
    before(:each) do 
      HTTParrot::ResponseFactory.clear!
      HTTParrot::Config.config[:template_root] = File.dirname(__FILE__)
      HTTParrot::ResponseFactory.define(:widget) { |r| r.widget_header = "SERVER" }
      @widget = HTTParrot::ResponseFactory.build(:widget)
      @server.clear!
    end

    it "registers call_handlers" do 
      handlers = @server.instance_variable_get("@call_handlers")
      handlers.each_value {|v| v.should be_empty }
      @server.register(:get, lambda{ |v| v =~ /widget/ }, @widget.to_rack)
      handlers[:get].should_not be_empty
      handlers[:post].should be_empty
    end

    it "registers regex_handlers" do 
      handlers = @server.instance_variable_get("@regex_handlers")
      handlers.each_value {|v| v.should be_empty }
      @server.register(:get, /widget/, @widget.to_rack)
      handlers[:get].should_not be_empty
      handlers[:post].should be_empty
    end

    it "registers endpoint_handlers" do 
      handlers = @server.instance_variable_get("@endpoint_handlers")
      handlers.each_value {|v| v.should be_empty }
      @server.register(:get, "/widget", @widget.to_rack)
      handlers[:get].should_not be_empty 
      handlers[:post].should be_empty
    end

    it "registers complex_handlers" do 
      handlers = @server.instance_variable_get("@complex_handlers")
      handlers.each_value {|v| v.should be_empty }
      @server.register(:get, ["/widget", /widget/], @widget.to_rack)
      handlers[:get].should_not be_empty
      handlers[:post].should be_empty
    end
    
    it "can simulate slow connections" do
      handler = @server.register(:get, ["/widget", /widget/], @widget.to_rack, :delay => 0.5)
      
      # stub sleep
      @server.stub!(:sleep)
      @server.should_receive(:sleep).with(0.5)
      @server.send(:increment_return, handler)
    end

    it "raises error when handler type cannot be inferred" do 
      expect{ @server.register(:get, 1, @widget.to_rack) }.to raise_error(/callable/)
    end

  end

end
