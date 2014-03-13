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

		# Uncomment to gives user at least one default event.

		# if @user_events.blank?
		# 	event_result = current_user.events.create(title: "Example Event!", start_time: 1200, end_time: 1400)
		# 	@user_events = current_user.events
		# end

		render :view_events

	end

	def add_event

		render :add_event
	end

	def submit_new_event
		@errors = []

		# Check to make sure no parameters are empty. If so, reject immediately
		if params[:title].empty? || params[:start_time].empty? || params[:end_time].empty?
			@errors.push("Invalid Input: Non-filled fields")
			render :add_event
			return
		end
		# Convert parameters to appropriate types
		title = params[:title]
		start_time = params[:start_time].to_i
		end_time = params[:end_time].to_i

		# Validate inputs
		if (title.length > MAX_TITLE_LENGTH)
			@errors.push("Invalid Title: More than 128 characters")
		end
		if (start_time < 0) || (end_time < 0)
			@errors.push("Invalid Time: Seriously? Negative?")
		end
		if ((start_time % 100) % 60) != (start_time % 100) || (start_time % 2400) != start_time
			@errors.push("Invalid Time: Start Time not correct format [hhmm]")
		end
		if ((end_time % 100) % 60) != (end_time % 100) || (end_time % 2400) != end_time
			@errors.push("Invalid Time: End Time not correct format [hhmm]")
		end

		# If any errors occur, reject event creation and display errors
		if not @errors.empty?
			render :add_event
			return
		end

		# Create new event through user to create association
		current_user.events.create(title: title, start_time: start_time, end_time: end_time)

		# After successful event creation, render view of all user events
		redirect_to :action => 'view_events'
		return

	end

	def delete_event
		# Convert necessary parameters into expected type
		id = params[:event_id].to_i

		# Ensure user owns event before deleting
		if not current_user.events.where(id: id).empty?
			current_user.events.find(id).destroy
		end

		# Redisplay the events page.
		# TODO: update with redirect
		redirect_to :action => 'view_events'
		return
	end

	def json_get_user_events
		@user_events = current_user.events.order(start_time: :asc, end_time: :asc)
	end

	def json_add_user_event
		@errors = []

		# Check to make sure no parameters are empty. If so, reject immediately
		if params[:title].empty? || params[:start_time].empty? || params[:end_time].empty?
			@errors.push("Invalid Input: Non-filled fields")
			render :add_event
			return
		end
		# Convert parameters to appropriate types
		title = params[:title]
		start_time = params[:start_time].to_i
		end_time = params[:end_time].to_i

		# Validate inputs
		if (title.length > MAX_TITLE_LENGTH)
			@errors.push("Invalid Title: More than 128 characters")
		end
		if (start_time < 0) || (end_time < 0)
			@errors.push("Invalid Time: Seriously? Negative?")
		end
		if ((start_time % 100) % 60) != (start_time % 100) || (start_time % 2400) != start_time
			@errors.push("Invalid Time: Start Time not correct format [hhmm]")
		end
		if ((end_time % 100) % 60) != (end_time % 100) || (end_time % 2400) != end_time
			@errors.push("Invalid Time: End Time not correct format [hhmm]")
		end

		# If any errors occur, reject event creation and display errors
		if not @errors.empty?
			render :add_event
			return
		end

		# Create new event through user to create association
		current_user.events.create(title: title, start_time: start_time, end_time: end_time)
	end

	def json_delete_user_event

	end
end
