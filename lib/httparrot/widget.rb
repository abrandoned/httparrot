require 'erb'
require 'ostruct'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/string/inflections'

module HTTParrot

  class Widget < OpenStruct

    def initialize(defaults = {})
      @parent_overwrite = false 
      super(defaults)
    end

    def parent(parental_class, defaults={})
      case
      when parental_class.is_a?(Symbol) then
        parental_class = HTTParrot::ResponseFactory.build(parental_class, defaults)
      when !parental_class.respond_to?(:to_hash) then
        raise "Parent must be a symbol or respond_to #to_hash"
      end 

      merge_parent(parental_class)
    end

    def parent!(parental_class, defaults = {})
      @parent_overwrite = true
      parent(parental_class, defaults)
      @parent_overwrite = false
    end

    def rack_response(response_code = 200)
      rendered_response = self.to_s
      return [response_code, {"Content-Length" => rendered_response.size.to_s}, [rendered_response]]
    end
    alias_method :to_rack, :rack_response
    alias_method :to_rack_response, :rack_response

    def to_hash
      self.marshal_dump
    end

    def to_s
      set_template_file

      if @table.has_key?(:template_file)
        file_string = File.read(file_template)
        current_template = ERB.new(file_string, nil, "<>")
        return current_template.result(binding) 
      else
        warn_no_template
        return self.inspect
      end
    end

    private

    def merge_parent(parental_class)
      case 
      when @parent_overwrite then
        @table.merge!(parental_class.to_hash)
      else
        @table.merge!(parental_class.to_hash.merge(@table))
      end
    end

    def set_template_file
      if self.template_file.nil? || self.template_file.empty?
        template_root = HTTParrot::Config.config[:template_root]
        filename = "#{self._class.gsub("Widget::", "").underscore}.erb"
        self.template_file = Dir.glob(template_root + "/**/" + filename).first
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
              a rack_response, define a template file to render with.

              Called at:

              #{e.backtrace.join("#{$/}      ")}
          ===================================================================
      WARNING
    end

  end

end
