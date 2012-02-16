# Mock server to accept requests and return known responses based on request content 
#
# influenced by: http://dynamicorange.com/2009/02/18/ruby-mock-web-server
require 'openssl' unless defined?(JRUBY_VERSION)
require 'ostruct'
require 'net/http'
require 'net/https'
require 'webrick'
require 'webrick/https'
require 'rack'
require 'thread'

module HTTParrot 

  class Server

    attr_accessor :options

    def initialize(opts={})
      @server_started = @server = nil
      @server_thread = nil
      @secure_started = @secure_server = nil
      @secure_thread = nil

      @parent_thread = Thread.current
      @options = { 
        :Port => 4000, 
        :Host => "127.0.0.1"
      }.merge(HTTParrot::Config.config).merge(opts)

      # hard to believe, but it's true, some people still use Windows! like me.
      isWindows = RUBY_PLATFORM.downcase =~ /mswin|windows|mingw/i
      quiet_options = { 
        :Logger => WEBrick::Log::new(isWindows ? "nul" : "/dev/null", 7),
        :AccessLog => []
      }

      @options.merge!(quiet_options) unless HTTParrot::Config.verbose

      self.clear!
    end

    def clear!
      blank_handler = {
        :get => [], 
        :post => [], 
        :head => [], 
        :delete => []
      }

      # Using Marshal for deep copy purposes
      # slow from an efficiency perspective, but #clear! 
      # is not called frequently and this gem is for testing
      @call_handlers = Marshal.load(Marshal.dump(blank_handler)) 
      @regex_handlers = Marshal.load(Marshal.dump(blank_handler)) 
      @endpoint_handlers = Marshal.load(Marshal.dump(blank_handler)) 
      @complex_handlers = Marshal.load(Marshal.dump(blank_handler))
      self
    end

    def reset_counts
      [@call_handlers, @regex_handlers, @endpoint_handlers, @complex_handlers].each do |handler_type|
        handler_type.each_key do |req_meth|
          handler_type[req_meth].each { |handler| handler.response_count = 0 }
        end
      end
    end

    def call(env)
      req = Rack::Request.new(env)
      response = respond_with(env)

      # TODO move this to WEBrick's builtin logging facilities
      if ENV["PARROT_VERBOSE"] || HTTParrot::Config.verbose
        puts "\n>>>>> REQUEST\n"
        puts req.inspect
        #puts req.body.string

        puts "\n<<<<< RESPONSE\n"
        puts response.inspect
        #response[2].each{ |l| puts l }
      end

      return response

    rescue Exception => e
      # reraise the exception in the parent thread if it Errors out
      @parent_thread.raise e
    end

    def register(http_method, method_key, response, call_with_env = false)
      http_method = http_method.to_s.downcase.to_sym
      raise "http_method in register must be one of [:get, :post, :head, :delete] : #{http_method}" if ![:get, :post, :head, :delete].include?(http_method)

      response_handler = OpenStruct.new({
        :method_key => method_key,
        :response => response,
        :env? => call_with_env,
        :response_count => 0
      })

      case
      when method_key.respond_to?(:call) then
        @call_handlers[http_method] << response_handler      
      when method_key.is_a?(Regexp) then
        @regex_handlers[http_method] << response_handler 
      when method_key.is_a?(String) then
        @endpoint_handlers[http_method] << response_handler 
      when method_key.is_a?(Array) then
        @complex_handlers[http_method] << response_handler        
      else
        raise "method_key (Handler) must be callable, Regexp, Array, or String" 
      end

      return response_handler
    end

    def start(startup_interval = 1)
      start_server
      start_secure_server if options[:ssl]
      sleep startup_interval # Ensure the server has time to startup
      sleep startup_interval if !running? # Give it a little more time if they didn't start
    end

    def running?
      secure_run_running = options[:ssl] ? (!@secure_server.nil? && @secure_started) : true
      @server_started && !@server.nil? && secure_run_running 
    end
    alias_method :started?, :running?

    def stop(shutdown_interval = 0)
      @server.shutdown if @server.respond_to?(:shutdown)
      @secure_server.shutdown if @secure_server.respond_to?(:shutdown)
      sleep shutdown_interval
      Thread.kill(@server_thread) if !@server_thread.nil?
      Thread.kill(@secure_thread) if !@secure_thread.nil?
      @server_started = @server = nil
      @secure_started = @secure_server = nil
    end

    private

    # Increment the number of times a handler was used (for asserting usage)
    def increment_return(handler)
      handler.response_count = handler.response_count + 1
      return handler.response
    end

    def call_handler_match?(call_handler, env, request, request_method, request_body)
      call_arg = (call_handler.env? ? env : request_body)

      return call_handler.method_key.call(call_arg)
    end

    def complex_handler_match?(complex_handler, env, request, request_method, request_body)

      complex_handler.method_key.inject(true) do |matching, handler|
        current_handler_match = false

        if matching
          current_handler = OpenStruct.new({
            :env? => complex_handler.env?,
            :method_key => handler
          })

          case 
          when handler.respond_to?(:call) then
            current_handler_match = call_handler_match?(current_handler, env, request, request_method, request_body)    
          when handler.is_a?(Regexp) then
            current_handler_match = regex_handler_match?(current_handler, env, request, request_method, request_body)
          when handler.is_a?(String) then
            current_handler_match = endpoint_handler_match?(current_handler, env, request, request_method, request_body)
          end
        end

        matching && current_handler_match
      end
    end

    def endpoint_handler_match?(endpoint_handler, env, request, request_method, request_body)
      return request.path_info =~ /#{endpoint_handler.method_key}/i
    end

    def regex_handler_match?(regex_handler, env, request, request_method, request_body)
      return regex_handler.method_key =~ request_body
    end

    def respond_with(env)
      req = Rack::Request.new(env)
      req_meth = req.request_method.downcase.to_sym
      request_body = req.body.string

      @complex_handlers[req_meth].each do |com_handler|
        return increment_return(com_handler) if complex_handler_match?(com_handler, env, req, req_meth, request_body)
      end

      @call_handlers[req_meth].each do |call_handler|
        return increment_return(call_handler) if call_handler_match?(call_handler, env, req, req_meth, request_body) 
      end

      @regex_handlers[req_meth].each do |reg_handler|
        return increment_return(reg_handler) if regex_handler_match?(reg_handler, env, req, req_meth, request_body) 
      end

      @endpoint_handlers[req_meth].each do |end_handler|
        return increment_return(end_handler) if endpoint_handler_match?(end_handler, env, req, req_meth, request_body) 
      end

      return no_mock_error(req_meth)
    end

    def no_mock_error(request_method)
      error_message = "No matched request handlers for: #{request_method}"
      [404, { "Content-Type" => "text/plain", "Content-Length" => error_message.size.to_s }, [error_message]]
    end

    def start_server
      if @server_thread.nil? || !@server_thread.alive?
        @server_thread = Thread.new(self, @options) do |server, options| 
          Rack::Handler::WEBrick.run(server, options) { |s| @server = s }
        end

        trap(:INT){ @server_thread.terminate; @server_thread = nil }
        @server_started = true
      end
    end

    def start_secure_server
      if @secure_thread.nil? || !@secure_thread.alive?
        @secure_thread = Thread.new(self, @options) do |server, options| 
          options = options.merge(:Port => options[:SSLPort],
                                  :SSLEnable => true,
                                  :SSLVerifyClient => OpenSSL::SSL::VERIFY_NONE,
                                  :SSLCertificate => ssl_cert,
                                  :SSLPrivateKey => ssl_key,
                                  :SSLCertName => [[ "CN", "127.0.0.1" ]])

          Rack::Handler::WEBrick.run(server, options) { |s| @secure_server = s }
        end

        trap(:INT){ @secure_thread.terminate; @secure_thread = nil }
        @secure_started = true
      end
    end

    def ssl_key
      OpenSSL::PKey::RSA.new(File.read(File.dirname(__FILE__) + "/ssl/" + "server.key"), "httparrot")
    end

    def ssl_cert
      OpenSSL::X509::Certificate.new(File.read(File.dirname(__FILE__) + "/ssl/" + "server.crt"))
    end

  end

end
