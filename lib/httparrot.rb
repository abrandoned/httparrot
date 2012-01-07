require "httparrot/version"
require "httparrot/server"
require "httparrot/response_factory"

require "ostruct"
require "thread"

module HTTParrot
  class Config 
    @config = OpenStruct.new

    def self.configure 
      yield self
    end

    def self.config
      @config.instance_variable_get(:@table)
    end

    def self.valid_key?(key)
      [ :Port, 
        :SSLPort,
        :ssl,
        :template_root,
        :verbose ].include?(key)
    end

    def self.restore_defaults
      self.configure do |c|
        c.Port = 4000
        c.SSLPort = c.Port + 1
        c.ssl = true
        c.verbose = false
        c.template_root = nil
      end
    end

    def self.method_missing(sym, *args, &blk)
      case 
      when sym.to_s =~ /(.+)=$/ && valid_key?($1.to_sym) then
        @config.send(sym, *args, &blk)
      when @config.respond_to?(sym) then
        @config.send(sym, *args, &blk)
      else 
        super
      end
    end

  end
end

HTTParrot::Config.restore_defaults
