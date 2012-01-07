require 'erb'
require 'ostruct'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/string/inflections'

module HTTParrot

  class Widget < OpenStruct

    def parent(parental_class, defaults={})
      case
      when parental_class.is_a?(Symbol) then
        parental_class = HTTParrot::ResponseFactory.build(parental_class, defaults)
      end

      self.marshal_load(parental_class.marshal_dump)
    end

    def options
      return @table
    end

    def rack_response(response_code = 200)
      rendered_response = self.to_s
      return [response_code, {"Content-Length" => rendered_response.size.to_s}, [rendered_response]]
    end
    alias_method :to_rack, :rack_response
    alias_method :to_rack_response, :rack_response

    def to_s
      if self.options.has_key?(:template_file)
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

    def warn_no_template
      raise "foo"
    rescue => e
      warn <<-WARNING
          ==============================================================
              #{self.class} does not have a template_file associated

              This will leave the response as an inspection of the class
              and is probably not the intended behavior.  Before returning
              a rack_response, you should define a template file to render
              the response with.

              Called at:

              #{e.backtrace.join("#{$/}      ")}
          ==============================================================
      WARNING
    end

  end

end
