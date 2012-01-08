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

  context "#parent" do 

  end

  context "#parent!" do 

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
