class Schedule < ActiveRecord::Base



    has_many :us_ss_relations, dependent: :destroy
    has_many :users, through: :us_ss_relation
    has_many :ss_es_relations, dependent: :destroy
    has_many :events, through: :ss_es_relations #, order: [:start_time, :end_time]

    @@EVENT_ID = 0
    @@FREE_ID = 1
    @@TRAVEL_ID = 2

    INFINITY = Float::INFINITY



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
    @travel_memo = {}
    def self.travel_time(origin, destination)
        if @travel_memo.key?([origin.id, destination.id])
            return @travel_memo[[origin.id, destination.id]]
        end
        if @travel_memo.key?([destination.id,origin.id])
            return @travel_memo[[destination.id,origin.id]]
        end
        url = "http://maps.googleapis.com/maps/api/directions/json?"
        # Add origin
        url += "origin=" + origin.latitude.to_s + "," + origin.longitude.to_s
        # Add destination
        url += "&destination=" + destination.latitude.to_s + "," + destination.longitude.to_s
        # Add additional params [ALWAYS DRIVING]
        # TODO: Add ability to indicate travel type
        url += "&sensor=false" + "&mode=driving"
        transit_JSON = open(url)
        transit_info = JSON.parse(transit_JSON)

        transit_time = transit_info["routes"]
        if transit_time.empty?
            # wait statement
            # Recursive call
            puts "NO ROUTE FOUND"
            puts "origin: " + origin.title + " " + origin.to_s
            puts "destination: " + destination.title + " " + destination.to_s
            sleep(1)
            transit_time = travel_time(origin, destination)
            return transit_time
        end
        transit_time = transit_time.first["legs"].first["duration"]["text"].split(" ")
        # Could cause errors if no route exists
        if (transit_time.length == 4)
            if (transit_time[1] = "days")
                return 2359
            else
                @travel_memo[[origin.id, destination.id]] = transit_time[0].to_i * 100 + transit_time[2].to_i
                return transit_time[0].to_i * 100 + transit_time[2].to_i
            end
        else
            @travel_memo[[origin.id, destination.id]] = transit_time[0].to_i
            return transit_time[0].to_i
        end
    end

    def self.travel_memo
        return @travel_memo
    end


    def find_sched_start()
        return this.events.order(start_time: :asc).first.start_time
    end
    
    def find_sched_end()
        return this.events.order(end_time: :desc).first.end_time 
    end 
    
    # Find earliest start time in a list of events
    def self.earliest_start_time(event_list)
        earliest_time = INFINITY
        event_list.each do |e|
            if e.start_time < earliest_time
                earliest_time = e.start_time
            end
        end
        return earliest_time
    end

    # Find latest end time in list of events
    def self.latest_end_time(event_list)
        latest_time = 0 - INFINITY
        event_list.each do |e|
            if e.end_time > latest_time
                latest_time = e.end_time
            end
        end
        return latest_time
    end


    # Tarek: Score
    # Ryan: Fits
    # Dalton: Sits (formerly known as Add)
    # Max: Dynamic Program
    def self.find_events(itin)
        event_list = []
        itin.each_with_index do |n, index|
            if n.type == 0
                event_list.push(n.event)
            end
        end
        return event_list
    end

    # TODO: Add constraints
    @schedule_memo = {}

    def self.schedule_events(itin, e, rem_events, opt_flag)
        # Sanitize inputs
        # puts "CALLING FUNCTION"
        rem_events = rem_events.to_a
        
        # Initialize if first call
        if (itin.empty?)
            # puts "Earliest Start: " + earliest_start_time(rem_events).to_s
            # puts "Latest End: " + latest_end_time(rem_events).to_s
            itin = []
            sched_start = earliest_start_time(rem_events)
            sched_end = latest_end_time(rem_events)
            itin.push(Node.new(sched_start, sched_end, time_between(sched_start, sched_end), 1, nil))
            @schedule_memo = {}
            new_itin = itin
            # puts "FINISHED INITIALIZING"
        else
            # Return memoized result if found

            event_list = find_events(itin).to_s
            rem_event_list = rem_events.to_s
            # TODO: ENSURE THAT THIS LOOKUP WORKS
            if @schedule_memo.has_key?([event_list, e, rem_event_list])
                puts "MEMOIZING!!!!"
                return @schedule_memo[[event_list, e, rem_event_list]]
            end


            # Ensure the event will fit
            puts "FITS INPUTS ITIN: " + itin.to_s
            puts "FITS INPUTS EVENT: " + e.title + ", " + e.to_s

            fits_value = fits(itin, e)
            # puts "FITS output: " + fits_value.to_s
            
            if not fits_value
                # puts "NO FIT"
                @schedule_memo[[event_list, e, rem_event_list]] = [itin, INFINITY]
                return [itin, INFINITY]
            end
            # Add event to itinerary
            # puts "SITS INPUT ITIN: " + itin.to_s
            # puts "SITS INPUT EVENT: " + e.title
            new_itin = sits(itin, e, fits_value)
            # puts "SITS OUTPUT ITIN: " + new_itin.to_s
        end

        # If all events have been added, score itinerary
        if rem_events.empty?
        	# print "LENGTH\n"
        	# print itin.length
        	# print "\n"
            itin_score = score(new_itin, opt_flag)
            @schedule_memo[[event_list, e, rem_event_list]] = [new_itin, itin_score]
            return [new_itin, itin_score]
        end

        # initialize values for following loop
        potential_itins = []
        min_score = INFINITY
        best_itin = new_itin

        # Find the itinerary with the best (lowest) score
        rem_events.each_with_index do |ne, index|

            events_without_ne = rem_events.dup
            events_without_ne.delete_at(index)

            temp_result = schedule_events(new_itin, ne, events_without_ne, opt_flag)

            potential_itins.push(temp_result)
            if temp_result[1] < min_score
                min_score = temp_result[1]
                best_itin = temp_result[0]
            end
        end
        # Memoize and return result
        @schedule_memo[[event_list, e, rem_event_list]] = [best_itin, min_score]
        return [best_itin, min_score]
    end
    




    #Ryan DID THIS MESS needs travel time
    #first if checks free type, second checks start within free slot, third checks start + duration finishes in time
     def self.fits(itinerary, event)
     	#If no free space left, short-circuit
     	if itinerary[itinerary.length - 1].type == 0
     		return false
     	end

     	#Then the Node after the last event in the itin must be contain Freespace

        free = lastevent(itinerary) + 1
        if free == 0
            return event.start_time
        end

        #Calculate the time it takes to get to the prev. event from our new event
        #If the start time is after the start of the free time plus travel time
        # puts "FITS: first event: " + itinerary[free-1].event.to_s
        # puts "FITS: second event: " + event.to_s + event.title

        travel = travel_time(itinerary[free-1].event, event)

        if event.start_time >= time_plus_duration(itinerary[free].start,travel)

        # if event.start_time >= itinerary[free].start + travel
            return event.start_time
        end


        if time_minus_duration(event.end_time,event.duration) >= time_plus_duration(itinerary[free].start , travel)
            if time_plus_duration(time_plus_duration(itinerary[free].start,travel), event.duration) <= itinerary[free].endtime
                return time_plus_duration(itinerary[free].start, travel)
            end
        end
        #No space :,(
        return false
    end

    
    def self.score(itin,optim)
    	#By the end of the following for loop:
    	#earliest- contains the earliest event start time of the itiner
    	#latest- contains the latest event end time of the itiner
        earliest = 2500
        latest = 0
        total_travel_time = 0
        number_free_slots = 0
        total_free_time = 0
        itin.each do |node|
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
	        when 1  #minimize total free time  // WHAT why would someone do this?
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
        i = itinerary.length-1

        while i >= 0 do
            if not itinerary[i].nil?
                if (itinerary[i].type == 0)
                    return i
                end
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
                return "(start: " + @start.to_s + ", " + "event: " + event.title.to_s + ", " + "end: " + @endtime.to_s + ")" 
            else
                return "(start: " + @start.to_s + ", " + "type: " + kind.to_s + ", " + "end: " + @endtime.to_s + ")"
            end
        end
    end

    def self.sits(itiner, event, fits_start)
        # Added to attempt to fix -Max
        itiner = itiner.dup

        length = itiner.length
        e_start = event.start_time
        e_end = event.end_time
        e_duration = event.duration
        #DO NOT USE TIME_PLUS_DURATION
        fits_end = fits_start+e_duration

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
            # FIX: e_end => fits_end -Max
            if itin_end != fits_end
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
            # puts "SITS: prev_event: " + prev_event.to_s
            # puts "SITS: event: " + event.to_s
            travel_time = travel_time(prev_event.event, event)
            #Time we should start traveling
            # print "\n"
            # print fits_start
            # print "\n"
            fits_travel_start = time_minus_duration(fits_start, travel_time) 
            itiner.pop()

            #If there is free time after our previous event, make a free time node
            if fits_travel_start > prev_event_end
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

    def self.new_node(starttime,endtime,duration,type,event)
    	return Node.new(starttime,endtime,duration,type,event)
    end
       
    def self.new_event(title, start_time, end_time, duration, address)
        return Event.create(title: title, start_time: start_time, 
            end_time: end_time, duration: duration, address: address)
    end

end