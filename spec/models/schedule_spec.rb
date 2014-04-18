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
		#print newItin[0].start
		expect(f1e).to eq(true)  
  #pending "add some examples to (or delete) #{__FILE__}"
  	end

  	it "tests score" do
  		firstNode = Schedule.new_node(800,2400,1600,1,nil)
  		itin1 = [firstNode]
  		itin2 = [firstNode]
  		e = Schedule.new_event("sleep",800,1000,100,"2200 Durant, Berkeley")
  		e2 = Schedule.new_event("eat",900,1100,100,"2200 Durant, Berkeley")
  		e3 = Schedule.new_event("work",1000,1200,100,"2200 Durant")
  		e4 = Schedule.new_event("code",1100,1300,100,"2200 Durant")
  		i1 = Schedule.sits(itin1,e, 800)
  		i2 = Schedule.sits(i1,e2, 900)
  		i3 = Schedule.sits(i2, e3, 1000)
  		final_itin1 = Schedule.sits(i3,e4,1100)
  		e1 = Schedule.new_event("sleep",800,1000,100,"2200 Durant")
  		e21 = Schedule.new_event("eat",1000,1100,100,"2200 Durant")
  		e31 = Schedule.new_event("work",1000,1200,100,"2200 Durant")
  		e41 = Schedule.new_event("code",1100,1300,100,"2200 Durant")
  		a1 = Schedule.sits(itin2,e1,800)
  		a2 = Schedule.sits(a1,e21,1000)
  		a3 = Schedule.sits(a2,e31,1100)
  		a4 = Schedule.sits(a3,e41,1200)
  		score1 = Schedule.score(i2,2)
  		score2 = Schedule.score(a4,2)
  		boo = score1 < score2
  		expect(boo).to eq(true)
  	end
    
    it "tests fits" do
  		firstNode = Schedule.new_node(800,2400,1600,1,nil)
  		itin1 = [firstNode]
  		itin2 = [firstNode]
  		e = Schedule.new_event("sleep",800,1000,100,"2200 Durant")
  		e2 = Schedule.new_event("eat",900,1100,100,"2200 Durant")
  		e3 = Schedule.new_event("work",1000,1200,100,"2200 Durant")
  		e4 = Schedule.new_event("code",1100,1300,100,"2200 Durant")
        t = Schedule.fits(itin1,e)
        expect(Schedule.fits(itin1,e)==false).to eq(false)
  		i1 = Schedule.sits(itin1,e, t)
        t = Schedule.fits(i1,e2)
        expect(Schedule.fits(i1,e2)==false).to eq(false)
  		i2 = Schedule.sits(i1,e2, t)
        t = Schedule.fits(i2,e3)
        expect(Schedule.fits(i2,e3)==false).to eq(false)
  		i3 = Schedule.sits(i2, e3, t)
        t = Schedule.fits(i3,e4)
        expect(Schedule.fits(i3,e4)==false).to eq(false)
  		final_itin1 = Schedule.sits(i3,e4,t)
  		e1 = Schedule.new_event("sleep",800,900,100,"2200 Durant")
  		e21 = Schedule.new_event("eat",900,1000,100,"2200 Durant")
  		e31 = Schedule.new_event("work",800,900,100,"2200 Durant")
  		e41 = Schedule.new_event("code",830,1130,100,"2200 Durant")
  		a1 = Schedule.sits(itin2,e1,800)
  		a2 = Schedule.sits(a1,e21,900)
  		expect(Schedule.fits(a2, e31)).to eq(false)
        expect(Schedule.fits(a2,e41)==false).to eq(false)

  	end

  	it "simple test dp" do
  		firstNode = Schedule.new_node(800,2400,1600,1,nil)
  		itin1 = [firstNode]
  		e = Schedule.new_event("sleep",800,1000,100,"2200 Durant")
  		e2 = Schedule.new_event("eat",900,1100,100,"2200 Durant")
  		e3 = Schedule.new_event("work",1000,1200,100,"2200 Durant")
  		e4 = Schedule.new_event("code",1100,1300,100,"2200 Durant")
  		rem_events = []
  		rem_events.push(e2)
  		rem_events.push(e3)
  		rem_events.push(e4)
  		a = Schedule.schedule_events(itin1,e,rem_events,2)
  		print a[0]
  		expect(a[0][0].event.title == "sleep")
  		expect(a[0][1].type == 2) #assert it is a travel node
  		expect(a[0][2].event.title == "eat")
  		expect(a[0][3].type == 2)
  		expect(a[0][4].event.title == "work")
  		expect(a[0][5].type == 2)
  		expect(a[0][6].event.title == "code")
  		expect(a[0].length).to eq(8)
  	end

  	it "schedules events that are too long" do
  		firstNode = Schedule.new_node(800,2400,1600,1,nil)
  		itin1 = [firstNode]
  		e = Schedule.new_event("sleep",800,2400,600,"2200 Durant")
  		e2 = Schedule.new_event("eat",900,2400,700,"2200 Durant")
  		e3 = Schedule.new_event("work",1000,2000,800,"2200 Durant")
  		e4 = Schedule.new_event("code",1100,2200,500,"2200 Durant")
  		rem_events = []
  		rem_events.push(e2)
  		rem_events.push(e3)
  		rem_events.push(e4)
  		a = Schedule.schedule_events(itin1,e,rem_events,2)
  		INFINITY = Float::INFINITY
  		expect(a[1]).to eq(INFINITY)
  	end

    it "schedules too many events" do
  		firstNode = Schedule.new_node(800,2400,1600,1,nil)
        itin1 = [firstNode]
  		e = Schedule.new_event("sleep",800,1000,100,"2200 Durant")
  		e2 = Schedule.new_event("eat",900,1100,100,"2200 Durant")
  		e3 = Schedule.new_event("work",1000,1200,100,"1515 Delaware, Berkeley")
  		e4 = Schedule.new_event("code",1100,1300,100,"2226 Durant")
  		e5 = Schedule.new_event("watchtv",1200,1500,300,"1527 Hearst, Berkeley")
  		e6 = Schedule.new_event("gym",1500,1900,300,"2360 Ellsworth, Berkeley")
  		e7 = Schedule.new_event("sleepagain",1900,2400,500,"2360 Ellsworth, Berkeley")
  		e8 = Schedule.new_event("willnotfit",1900,2100,100,"2360 Ellsworth, Berkeley")
  		rem_events = []
  		rem_events.push(e2)
  		rem_events.push(e3)
  		rem_events.push(e4)
  		rem_events.push(e5)
  		rem_events.push(e6)
  		rem_events.push(e7)
  		rem_events.push(e8)
  		a = Schedule.schedule_events(itin1,e,rem_events,2)
  		INFINITY = Float::INFINITY
  		expect(a[1]).to eq(INFINITY)
    end
    
    it "test fits no free space" do
        firstNode = Schedule.new_node(800,2400,1600,1,nil)
  		itin1 = [firstNode]
        e = Schedule.new_event("sleep",800,2400,1600,"2200 Durant")
        expect(Schedule.fits(itin1,e)==800).to eq(true)
        i1 = Schedule.sits(itin1,e,800)
        e2 = Schedule.new_event("eat",900,1100,100,"2200 Durant")
        expect(Schedule.fits(i1, e2)).to eq(false)
    end
    
    it "test fits no free space 2" do
        firstNode = Schedule.new_node(800,2400,1600,1,nil)
  		itin1 = [firstNode]
        e = Schedule.new_event("eat",900,1100,100,"2200 Durant")
        expect(Schedule.fits(itin1,e)==900).to eq(true)
        i1 = Schedule.sits(itin1,e,800)
        e2 = Schedule.new_event("eat",1100,2400,1300,"2200 Durant")
        expect(Schedule.fits(i1, e2)==1100).to eq(true)
        i2 = Schedule.sits(i1,e2,1100)
        e3 = Schedule.new_event("code",800,1130,100,"2200 Durant")
        expect(Schedule.fits(i2,e3)).to eq(false)
    end
    
    end
