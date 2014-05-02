class UsersController < ApplicationController

	MAX_TITLE_LENGTH = 128
	INVALID_INPUT = -1
	SUCCESS = 1
	NO_RECORD = -2

	before_filter :authenticate_user!

	def index
  		@users = User.all
	end

	def view_events
		@user_events = current_user.events.order(start_time: :asc, end_time: :asc)
		render :view_events
	end

	def view_schedules
		@user_schedules = current_user.schedules.order(start_time: :asc, end_time: :asc)
		@errors = params[:errors]
		render :view_schedules
	end

	def view_one_schedule
		id = params[:schedule_id].to_i

		# Warning: Highjacking Schedule.has_events to control roundtrip
		@roundtrip_state = Schedule.find(id).has_events
		# Check if schedule is round-trip
		rt_val = (params[:roundtrip] == 'true')
		if rt_val == true
			# If true XOR with current state to flip
			Schedule.find(id).update(has_events: (@roundtrip_state ^ rt_val))
			@roundtrip_state = (@roundtrip_state ^ rt_val)
		end

		@user_events = current_user.events.order(start_time: :asc, end_time: :asc)
		@schedule = current_user.schedules.find(id)
		@event_list = current_user.schedules.find(id).events.order(start_time: :asc, end_time: :asc).to_a
		itinerary = Schedule.schedule_events([], nil, @event_list, 0)
		# @schedule_events = Schedule.find_events(itinerary[0])
		# Warning: Highjacking Schedule.has_events to control roundtrip


		@schedule_events = itinerary[0]
		puts "SCHEDULE: " + itinerary[0].to_s
		puts "SCHEDULE LENGTH: " + itinerary[0].length.to_s
		itin_type = itinerary[0]
		itin_type = itin_type[0].type
		puts "SCHEDULE TYPE: " + itin_type.to_s
 		@errors = params[:errors]
		@newest_schedule_event = params[:newest_schedule_event]
		render :view_one_schedule
	end

	def add_event
		render :add_event
	end

	def edit_event
		id = params[:event_id].to_i
		begin
		  @event = current_user.events.find(id)
		rescue ActiveRecord::RecordNotFound => e
		  @event = nil #TODO: Redirects to another page
		end
		render :edit_event
	end

	def submit_new_event
		@errors = []

		# Check to make sure no parameters are empty. If so, reject immediately
		if params[:title].empty? || params[:start_time].empty? || params[:end_time].empty? || params[:duration].empty? || params[:address].empty?
			@errors.push("Invalid Input: Non-filled fields")
			render :add_event
			return
		end
		# Convert parameters to appropriate types
		title = params[:title]
		start_time = params[:start_time].to_i
		end_time = params[:end_time].to_i
		duration = params[:duration].to_i
		address = params[:address]


		# Validate inputs
		if (title.length > MAX_TITLE_LENGTH)
			@errors.push("Invalid Title: More than 128 characters")
		end
		if ((start_time % 100) % 60) != (start_time % 100) || (start_time % 2400) != start_time
			@errors.push("Invalid Time: Start Time not correct format [hhmm]")
		end
		if ((end_time % 100) % 60) != (end_time % 100) || (end_time % 2400) != end_time
			@errors.push("Invalid Time: End Time not correct format [hhmm]")
		end
		if ((end_time - start_time) < duration)
			@errors.push("Duration is longer than the time frame.")
		end
		if(duration > 2400)
			@errors.push("Duration is longer than 24 hours, please pick another event.")
		end
		if ((duration % 100) % 60) != (duration % 100) || (duration % 2400) != duration
			@errors.push("Duration is not in correct format[hhmm]")
		end

		# If any errors occur, reject event creation and display errors
		if not @errors.empty?
			render :add_event
			return
		end

		# Create new event through user to create association
		event = current_user.events.create(title: title, start_time: start_time, end_time: end_time, address: address, duration: duration)
		if event.latitude.nil? || event.longitude.nil?
			@errors.push("Invalid Location: Address could not be translated")
			current_user.events.find(event.id).destroy
			render :add_event
			return
		end
		# After successful event creation, render view of all user events
		redirect_to :action => 'view_events'
		return

	end

	def submit_edited_event
		@errors = []
		id = params[:event_id].to_i
		# Check to make sure no parameters are empty. If so, reject immediately
		if params[:title].empty? || params[:start_time].empty? || params[:end_time].empty? || params[:address].empty?
			@errors.push("Invalid Input: Non-filled fields")
			@event = current_user.events.find(params[:event_id].to_i)
			render :edit_event
			return
		end
		# Convert parameters to appropriate types
		title = params[:title]
		start_time = params[:start_time].to_i
		end_time = params[:end_time].to_i
		duration = params[:duration].to_i
		address = params[:address]

		# Validate inputs
		if (title.length > MAX_TITLE_LENGTH)
			@errors.push("Invalid Title: More than 128 characters")
		end
		if ((start_time % 100) % 60) != (start_time % 100) || (start_time % 2400) != start_time
			@errors.push("Invalid Time: Start Time not correct format [hhmm]")
		end
		if ((end_time % 100) % 60) != (end_time % 100) || (end_time % 2400) != end_time
			@errors.push("Invalid Time: End Time not correct format [hhmm]")
		end
		if ((end_time - start_time) < duration)
			@errors.push("Duration is longer than the time frame.")
		end
		if(duration > 2400)
			@errors.push("Duration is longer than 24 hours, please pick another event.")
		end

		# If any errors occur, reject event creation and display errors
		if not @errors.empty?
			@event = current_user.events.find(params[:event_id].to_i)
			render :edit_event
			return
		end

		# Create new event through user to create association
		old_event = current_user.events.find(id)
		current_user.events.find(id).update(title: title, start_time: start_time, end_time: end_time, address: address, duration: duration)
		new_event = current_user.events.find(id)

		# Due to behavior of geocoder, have to check that update does not corrupt address
		if (old_event.address != new_event.address) && (old_event.latitude == new_event.latitude) && (old_event.longitude == new_event.longitude)
			@errors.push("Invalid Location: Address could not be translated")
			@event = current_user.events.find(id)
			render :edit_event
			return
		end
		# After successful event creation, render view of all user events
		redirect_to :action => 'view_events'
		return
	end

	# Delete association between user and event and re-render view
	def delete_event
		# Convert necessary parameters into expected type
		id = params[:event_id].to_i

		# Ensure user owns event before deleting
		if not current_user.events.where(id: id).empty?
			UsEsRelation.where(user_id: current_user.id, event_id: id).destroy_all
		end


		# Redisplay the events page.
		# TODO: update with redirect
		redirect_to :action => 'view_one_schedule', schedule_id: params[:schedule_id], errors: @errors
		return
	end

	# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

	def submit_new_schedule
		@errors = []
		user_id = current_user.id

		if params[:title].empty? || params[:day].empty?
			@errors.push("Invalid Input: Non-filled fields")
			redirect_to :action => 'view_schedules', errors: @errors
			return
		end

		title = params[:title]
		start_time = params[:start_time].to_i
		end_time = params[:end_time].to_i
		day = params[:day].to_i


		if (title.length > MAX_TITLE_LENGTH)
			@errors.push("Invalid Title: More than 128 characters")
		end

		if ((day % 8) != day)
			@errors.push("Invalid Day: I'm impressed. How did you even do that?")
		end

		if not @errors.empty?
			redirect_to :action => 'view_schedules', errors: @errors
			return
		end

		schedule = current_user.schedules.create(title: title, start_time: 0, end_time: 2359, day: day, num_events: 0, has_events: false)
		
		redirect_to :action => 'view_schedules'
		return

	end

	def delete_schedule
		user_id = current_user.id
		schedule_id = params[:schedule_id].to_i

		if not current_user.schedules.where(id: schedule_id).empty?
			current_user.schedules.find(schedule_id).destroy
		end
		redirect_to :action => 'view_schedules'


	end

	def add_old_event_to_schedule
		user_id = current_user.id
		schedule_id = params[:schedule_id].to_i
		event_id = params[:event_id].to_i
		if current_user.events.where(id: event_id).blank?
			# RETURN ERROR
		end

		if SsEsRelation.where(schedule_id: schedule_id, event_id: event_id).blank?
			SsEsRelation.create(schedule_id: schedule_id, event_id: event_id)
			schedule = Schedule.find(schedule_id)
			schedule_events_start = schedule.events.order(start_time: :asc, end_time: :asc)
			schedule_events_end = schedule.events.order(end_time: :desc)
			Schedule.find(schedule_id).update(num_events: (schedule.num_events + 1), 
			start_time: schedule_events_start.first.start_time, end_time: schedule_events_end.first.end_time)
		end
		event = Event.find(event_id)

		@newest_schedule_event = event

		redirect_to :action => 'view_one_schedule', schedule_id: params[:schedule_id], newest_schedule_event: @newest_schedule_event
	end

	# input 2400 time format
    # outputs difference in 24 hour format
    def time_between(first_time, second_time)
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
    def time_plus_duration(time, duration)
        new_hour = (((time - (time % 100)) / 100) + ((duration - (duration % 100)) / 100)) % 24
        new_minute = (time % 100) + (duration % 100)
        if new_minute > 59
            new_hour = (new_hour + 1) % 24
            new_minute = new_minute % 60
        end
        return new_hour * 100 + new_minute
    end
    
    def time_minus_duration(time, duration)
        new_hour = (((time - (time % 100)) / 100) - ((duration - (duration % 100)) / 100)) % 24
        new_minute = (time % 100) - (duration % 100)
        if new_minute < 0
            new_hour = (new_hour - 1) % 24
            new_minute = new_minute % 60
        end
        return new_hour * 100 + new_minute
    end

	def add_new_event_to_schedule
		@errors = []
		@schedule_errors = []
		user_id = current_user.id
		schedule_id = params[:schedule_id].to_i

		if params[:title].empty? || params[:start_time].empty? || params[:end_time].empty? || params[:address].empty?
			@errors.push("Invalid Input: Non-filled fields")
			redirect_to :action => 'view_one_schedule', schedule_id: params[:schedule_id], errors: @errors
			return
		end
		# Convert parameters to appropriate types
		title = params[:title]
		start_time = params[:start_time].split(':').join("").to_i
		end_time = params[:end_time].split(':').join("").to_i
		duration = params[:duration].split(':').join("").to_i
		address = params[:address]

		# Validate inputs
		if (title.length > MAX_TITLE_LENGTH)
			@errors.push("Invalid Title: More than 128 characters")
		end
		if ((start_time % 100) % 60) != (start_time % 100) || (start_time % 2400) != start_time
			@errors.push("Invalid Time: Start Time not correct format [hhmm]")
		end
		if ((end_time % 100) % 60) != (end_time % 100) || (end_time % 2400) != end_time
			@errors.push("Invalid Time: End Time not correct format [hhmm]")
		end

		schedule = Schedule.find(schedule_id)

		if (start_time < schedule.start_time)
			@schedule_errors.push("Invalid Start Time: Before schedule starts.")
		end
		if (end_time > schedule.end_time)
			@schedule_errors.push("Invalid End Time: After schedule ends.")
		end

		if ((duration % 100) % 60) != (duration % 100) || (duration % 2400) != duration
			@errors.push("Duration is not in correct format[hhmm]")
		end

		if (time_between(start_time, end_time) < duration)
			@errors.push("Duration is longer than the time frame.")
		end

		# If any errors occur, reject event creation and display errors
		if not @errors.empty?
			redirect_to :action => 'view_one_schedule', schedule_id: params[:schedule_id], errors: @errors
			return
		end

		# Create new event through user to create association
		event = Schedule.find(schedule_id).events.create(title: title, start_time: start_time, end_time: end_time, address: address, duration: duration)

		if event.latitude.nil? || event.longitude.nil?
			@errors.push("Invalid Location: Address could not be translated")
			Schedule.find(schedule_id).events.find(event.id).destroy
			redirect_to :action => 'view_one_schedule', schedule_id: params[:schedule_id], errors: @errors
			return
		end

		if not params[:saving].nil?
			UsEsRelation.create(user_id: current_user.id, event_id: event.id)
		end

		schedule = Schedule.find(schedule_id)
		schedule_events_start = schedule.events.order(start_time: :asc, end_time: :asc)
		schedule_events_end = schedule.events.order(end_time: :desc)
		Schedule.find(schedule_id).update(num_events: (schedule.num_events + 1), 
			start_time: schedule_events_start.first.start_time, end_time: schedule_events_end.first.end_time)

		@newest_schedule_event = event

		redirect_to :action => 'view_one_schedule', schedule_id: params[:schedule_id], errors: @errors, newest_schedule_event: @newest_schedule_event

	end

	def delete_event_from_schedule
		user_id = current_user.id
		schedule_id = params[:schedule_id].to_i
		event_id = params[:event_id].to_i

		SsEsRelation.where(schedule_id: schedule_id, event_id: event_id).destroy_all

		schedule = Schedule.find(schedule_id)
		schedule_events_start = schedule.events.order(start_time: :asc, end_time: :asc)
		schedule_events_end = schedule.events.order(end_time: :desc)
		if (schedule.num_events > 1)
			Schedule.find(schedule_id).update(num_events: (schedule.num_events - 1), 
				start_time: schedule_events_start.first.start_time, end_time: schedule_events_end.first.end_time)
		else
			Schedule.find(schedule_id).update(num_events: (schedule.num_events - 1), 
				start_time: 0, end_time: 2359)
		end
		redirect_to :action => 'view_one_schedule', schedule_id: params[:schedule_id]
	end

	def delete_all_schedule_events
		user_id = current_user.id
		schedule_id = params[:schedule_id].to_i

		SsEsRelation.where(schedule_id: schedule_id).destroy_all
		schedule = Schedule.find(schedule_id)
		Schedule.find(schedule_id).update(num_events: 0, 
				start_time: 0, end_time: 2359)
		redirect_to :action => 'view_one_schedule', schedule_id: params[:schedule_id]
	end

end
