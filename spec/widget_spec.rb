require 'spec_helper'

describe HTTParrot::Widget do

  context "API" do 
    subject{ HTTParrot::Widget.new }

    specify{ subject.should respond_to(:rack_response) }
    specify{ subject.should respond_to(:to_hash) }
    specify{ subject.should respond_to(:to_rack) }
    specify{ subject.should respond_to(:to_rack_response) }
    specify{ subject.should respond_to(:parent) }
  end

  context "#parent" do 

  end


end
