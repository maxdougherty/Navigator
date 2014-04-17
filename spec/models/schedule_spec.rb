require 'spec_helper'

describe Schedule do
	it "adds event to schedule" do
		firstNode = Schedule.new_node(800, 2400, 1600, 1, nil)
		itin = [firstNode]
		e = Schedule.new_event("sleep",800,1300,100,"2200 Durant")
		newItin = Schedule.sits(itin, e, 800)
		f1 = newItin[0].type == 0
		f1e = newItin[0].endtime == 900
		expect(f1).to eq(true)
		print newItin[0].start
		expect(f1e).to eq(true)  
  #pending "add some examples to (or delete) #{__FILE__}"
  	end
end
