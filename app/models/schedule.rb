class Schedule < ActiveRecord::Base



    has_many :us_ss_relations, dependent: :destroy
    has_many :users, through: :us_ss_relation
    has_many :ss_es_relations, dependent: :destroy
    has_many :events, through: :ss_es_relations #, order: [:start_time, :end_time]

    @@EVENT_ID = 0
    @@FREE_ID = 1
    @@TRAVEL_ID = 2



    require "json"
    require "net/http"
    require "uri"
    require 'event'


    def self.open(url)
        return Net::HTTP.get(URI.parse(url))
    end

    # Params [origin:event, destination:event]
    # Returns time in 24-hour format
    # If travel time is greater than 24-hours, return 2359 as travel time
    def self.travel_time(origin, destination)
        url = "http://maps.googleapis.com/maps/api/directions/json?"
        # Add origin
        url += "origin=" + origin.latitude.to_s + "," + origin.longitude.to_s
        # Add destination
        url += "&destination=" + destination.latitude.to_s + "," + destination.longitude.to_s
        # Add additional params [ALWAYS WALKING]
        # TODO: Add ability to indicate travel type
        url += "&sensor=false" + "&mode=walking"
        transit_JSON = open(url)
        transit_info = JSON.parse(transit_JSON)

        transit_time = transit_info["routes"].first["legs"].first["duration"]["text"].split(" ")
        if (transit_time.length == 4)
            if (transit_time[1] = "days")
                return 2359
            else
                return transit_time[0].to_i * 100 + transit_time[2].to_i
            end
        else
            return transit_time[0].to_i
        end
    end


    def find_sched_start()
        return this.events.order(start_time: :asc).first.start_time
    end
    
    def find_sched_end()
        return this.events.order(end_time: :desc).first.end_time 
    end 
            


    # Tarek: Score
    # Ryan: Fits
    # Dalton: Sits (formerly known as Add)
    # Max: Dynamic Program

    # TODO: Add constraints
    def self.schedule_events(itin, e, rem_events)
    end
    
    #Ryan DID THIS MESS needs travel time
    #first if checks free type, second checks start within free slot, third checks start + duration finishes in time
     def self.fits(itinerary, event)
        free = lastevent(itinerary) + 1
        if free == 0
            return event.start_time
        end
        travel = travel_time(itinerary[free-1].event, event)
        if event.start_time >= itinerary[free].start + travel
            return event.start_time
        end
        if event.end_time - duration >= itinerary[free].start + travel
            return itinerary[free].start + travel
        end
        return false
    end

    
    def self.score(itin,optim)
        earliest = 2500
        latest = 0
        total_travel_time = 0
        number_free_slots = 0
        total_free_time = 0
        for node in itin
            if node.start < earliest && node.type == 0
                earliest = node.start
            end
            if node.endtime > latest && node.type == 0
                latest = node.endtime
            end
            if node.type == 2
                total_travel_time += node.duration
            end
            if node.type == 1
                total_free_time += node.duration
                number_free_slots += 1
            end
        end
        case optim
        when 0  #minimize total travel time
            return total_travel_time
        when 1  #minimize total free time 
            return total_free_time
        when 2 #minimize number free slots (gaps)
            return number_free_slots
        when 3 #maximize free time
            sched_time = latest - earliest
            return sched_time - total_free_time
        else #default
            return total_travel_time
        end
    end
    
    # input 2400 time format
    # outputs difference in 24 hour format
    def self.time_between(first_time, second_time)
        if (first_time == second_time)
            return 0
        end
        start_hour = ((first_time - (first_time % 100)) / 100)
        end_hour = ((second_time - (second_time % 100)) / 100)
        start_minutes = (first_time % 100)
        end_minutes = (second_time % 100)
        
        if second_time < first_time
            delta_hours = (24 + end_hour) - start_hour
        else
            delta_hours = end_hour - start_hour
        end
        delta_minutes = end_minutes - start_minutes
        if delta_minutes < 0
            delta_hours = (delta_hours - 1) % 24
            delta_minutes = (delta_minutes % 60)
        end
        
        return (100 * delta_hours) + delta_minutes
    end
    
    # 
    def self.time_plus_duration(time, duration)
        new_hour = (((time - (time % 100)) / 100) + ((duration - (duration % 100)) / 100)) % 24
        new_minute = (time % 100) + (duration % 100)
        if new_minute > 59
            new_hour = (new_hour + 1) % 24
            new_minute = new_minute % 60
        end
        return new_hour * 100 + new_minute
    end
    
    def self.time_minus_duration(time, duration)
        new_hour = (((time - (time % 100)) / 100) - ((duration - (duration % 100)) / 100)) % 24
        new_minute = (time % 100) - (duration % 100)
        if new_minute < 0
            new_hour = (new_hour - 1) % 24
            new_minute = new_minute % 60
        end
        return new_hour * 100 + new_minute
    end

#last event index or -1 if out of array bounds
    def self.lastevent(itinerary)
        i = itinerary.length
        while i > 0 do
            if (itinerary[i].type == 0)
                return i
            end
            i -= 1
        end
        return -1
    end
    
    class Node
        def initialize(start,endtime,duration,type,event)
            
            @start = start
            @endtime = endtime
            @duration = duration
            @type = type
            if (event.nil?)
                @event = nil
            else
                @event = event
            end
            @event = event
            
        end
               
        def start
            @start
        end
        
        def endtime
            @endtime
        end
        
        def duration
            @duration
        end
                     
        def type
            @type
        end
        
        def event
            @event
        end

        def to_s
            if type == 1
                kind = "Free"
            end
            if type == 2
                kind = "Travel"
            end
            if not event.nil?
                return "(start: " + @start.to_s + ", " + "event: " + event.title.to_s + ", " + "end: " + @endtime + ")" 
            else
                return "(start: " + @start.to_s + ", " + "type: " + kind.to_s + ", " + "end: " + @endtime.to_s + ")"
            end
        end
    end

    def self.sits(itiner, event, fits_start)
        length = itiner.length
        e_start = event.start_time
        e_end = event.end_time
        e_duration = event.duration 
        fits_end = time_plus_duration(fits_start,e_duration)

      #If this is our first event added, take special precautions
        if (length == 1)
            #Gather useful var and pop off the old freespace
            itin_start = itiner[0].start
            itin_end = itiner[0].endtime
            itiner.pop()

            #if there is free time before the scheduled event
            if itin_start != fits_start
                #Create the new free time node, and the new event node
                first_free = Node.new(itin_start, e_start, 
                                      time_between(itin_start, e_start), @@FREE_ID,nil)
                #push nodes to itinerary
                itiner.push(first_free)
            end

            #Add and push the event node
            event_node = Node.new(fits_start, fits_end,
                                  e_duration, @@EVENT_ID,event)
            itiner.push(event_node)

            #If there is free time after the event, push the node to the itin as well
            if itin_end != e_end
                last_free = Node.new(fits_end, itin_end, 
                                     time_between(fits_end, itin_end), @@FREE_ID,nil)
                itiner.push(last_free)
            end

        #If we are working with an itinerary with events already added
        else
            #Gather the start/end time of our last free time node
            free_start = itiner[length - 1].start
            free_end = itiner[length - 1].endtime
            #The most recent scheduled event should be right before the last node
            prev_event = itiner[length - 2]
            prev_event_end = prev_event.endtime
            #Travel time between prev. event and event we want to schedule
            travel_time = travel_time(prev_event.event, event)
            puts travel_time
            #Time we should start traveling
            fits_travel_start = time_minus_duration(fits_start, travel_time)
            itiner.pop()

            #If there is free time after our previous event, make a free time node
            if fits_travel_start != prev_event_end
                first_free = Node.new(prev_event_end, fits_travel_start, 
                                 time_between(prev_event_end, fits_travel_start), @@FREE_ID,nil)
                itiner.push(first_free)
            end

            #Add our travel node and event node
            travel_node = Node.new(fits_travel_start, fits_start, travel_time,
                                    @@TRAVEL_ID,nil)
            event_node = Node.new(fits_start, fits_end, e_duration, @@EVENT_ID,event)
            itiner.push(travel_node)
            itiner.push(event_node)

            #If there is free time at the end of itiner, free and push free space node
            if fits_end != free_end
                last_free = Node.new(fits_end, free_end,
                         time_between(fits_end, free_end), @@FREE_ID,nil)
                itiner.push(last_free)
            end
        end

        return itiner
    end
          
	def self.testAdd
		#Create initial freetime node from 8am to 12pm
		firstNode = Node.new(800, 2400, 1600, 1, nil)
		e = Event.create(title:"Event1",address:"Soda Hall", start_time:800, end_time:1200, duration:100)
		itin = [firstNode]


		newItin = sits(itin, e, 800)
		# [E:8-9, F:9-24]
		#The first node should contain the event and end at 900
		f1 = newItin[0].type == 0 && newItin[0].endtime == 900


		e1 = Event.create(title:"Event2",address:"Sproul Plaza, Berkeley, CA", start_time:1000, end_time:1200, duration:200)
		
		#[E:8-9, F:9-10ish, travel:0015, E:10-12, F12-24]
		newItin = sits(newItin, e1, 1000)
		f2 = newItin[1].type == 1 
		f3 = newItin[2].type == 2
		s3 = newItin[1].start
		f4 = newItin[3].type == 0 && newItin[3].endtime == 1200
		f4 = newItin[4].type == 1 && newItin[4].duration ==1200

		return ["Node 0 is even ending at 9: ",f1,
			"Node 1 is freetime: ",f2,
			"Node 2 is type travel: ", f3,
			"Duration of travel-time: ", s3,
			"Node 3 is event ending at 1200: " , f4,
			newItin]
		# return newItin
	end


end