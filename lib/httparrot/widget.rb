require 'erb'
require 'ostruct'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/string/inflections'

module HTTParrot

  class Widget < OpenStruct

    attr_accessor :parent_overwrite

    def initialize(defaults = {})
      @parent_overwrite = true
      super(defaults)
    end

    def parent(parental_class, defaults={})
      case
      when parental_class.is_a?(Symbol) then
        parental_class = HTTParrot::ResponseFactory.build(parental_class, defaults)
      when !parental_class.respond_to?(:to_hash) then
        raise "Parent must be a symbol or respond_to #to_hash"
      end 

      merge_parent
    end

    def parent_overwrite?
      @parent_overwrite
    end

    def rack_response(response_code = 200)
      rendered_response = self.to_s
      return [response_code, {"Content-Length" => rendered_response.size.to_s}, [rendered_response]]
    end
    alias_method :to_rack, :rack_response
    alias_method :to_rack_response, :rack_response

    def to_hash
      self.marshap_dump
    end

    def to_s
      if @table.has_key?(:template_file)
        file_template = File.dirname(File.expand_path(__FILE__)) 
        file_template = file_template + "/" + template_file
        file_string = File.read(file_template)

        current_template = ERB.new(file_string, nil, "<>")
        return current_template.result(binding) 
      else
        warn_no_template
        return self.inspect
      end
    end

    private

    def merge_parent
      case 
      when parent_overwrite? then
        @table.merge!(parental_class.to_hash)
      else
        @table.merge!(parental_class.to_hash.merge(@table))
      end
    end

    def warn_no_template
      raise "foo"
    rescue => e
      warn <<-WARNING
          ===================================================================
              #{self.class} does not have a template_file associated

              This will leave the response as an inspection of the class
              and is probably not the intended behavior.  Before returning
              a rack_response, you should define a template file to render
              the response with.

              Called at:

              #{e.backtrace.join("#{$/}      ")}
          ===================================================================
      WARNING
    end

  end

end
