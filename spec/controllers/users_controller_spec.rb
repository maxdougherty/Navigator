require 'spec_helper'

describe UsersController do
    
    ########Test the add functions#######
    login_user
    #current user is not nil
    it "should have a current_user" do
	subject.current_user.should_not be_nil
    end
    
    #No Events For User
    describe "new user with no events yet" do
        it "should give 'Example Event' for this user's event view" do
		@request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
		post :view_events
		response.body.should == [{id: '0', title: 'Example Event!', start_time: '1200', end_time: '1400'}].to_json
        end
    end

    #a user that has multiple events
    describe "a user that has multiple events" do
	  it "returns correct field values of an event when view events" do
		@expected = {title: "Testing", start_time: 1400, end_time: 2200}
		#we use the following to create new events directly instead of doing it via submit_new_event because we want to test this action only
		subject.current_user.events.create(@expected)
		@request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
		post :view_events
		parsed = ActiveSupport::JSON.decode(response.body)
		parsed.size.should == 1
		first_row = parsed.first.symbolize_keys
		first_row[:id].should == 1
		first_row[:title].should == "Testing"
		first_row[:start_time].should == 1400
		first_row[:end_time].should == 2200
	  end
    end

    describe "a user that has multiple events" do
	it "returns the correct number of events for a user" do
		@request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
		#Before adding any events
		post :view_events
		parsed = ActiveSupport::JSON.decode(response.body)
		parsed.size.should == 1
		
		@expected = {title: "Testing", start_time: 1400, end_time: 2200}
		#we use the following to create new events directly instead of doing it via submit_new_event because we want to test this action only
		(0..9).each do |i|
			subject.current_user.events.create(@expected)
		end
		post :view_events
		parsed = ActiveSupport::JSON.decode(response.body)
		parsed.size.should == 10
		
		#add one more
		subject.current_user.events.create(@expected)
		post :view_events
		parsed = ActiveSupport::JSON.decode(response.body)
		parsed.size.should == 11
	end
    end

    describe "a user that has multiple events" do
	it "should return the events sorted in the order ASC (start_time, end_time)" do
		@request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
		#add events in order DESC (start_time, end_time) which is the reversed order
		(0..9).each do |i|
			@expected = {title: "Testing", start_time: 0100*(9-i), end_time: 0200*(9-i)}
			subject.current_user.events.create(@expected)
		end
		post :view_events
		parsed = ActiveSupport::JSON.decode(response.body)
		parsed.size.should == 10

		#first event id should be 10 (last event added but sorted as first)		
		first_event = parsed.first.symbolize_keys
		first_event[:id].should == 10
		
		#check the rest in a loop
		(2..10).each do |i|
			event = parsed[i-1].symbolize_keys
			event[:id].should == 11-i
		end
	end
    end

    describe "when a user with no events tries to delete an event" do
	it "should do nothing and returns an Example Event" do
		@request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
		post :delete_event, :event_id => '0'
		response.body.should == [{id: '0', title: 'Example Event!', start_time: '1200', end_time: '1400'}].to_json
	end
    end

   describe "a user with multiple events delete an event in the middle of the sorted list" do
	it "should return with a list of events with the correct order" do
		@request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
		#add events in order DESC (start_time, end_time) which is the reversed order
		(0..9).each do |i|
			@expected = {title: "Testing", start_time: 0100*(9-i), end_time: 0200*(9-i)}
			subject.current_user.events.create(@expected)
		end
		post :delete_event, :event_id => '5' #the middle entry
		parsed = ActiveSupport::JSON.decode(response.body)
		parsed.size.should == 9 #check number of events correct?
		
		#check the returned events in a loop, we should get the events in this order of event_id: [10 9 8 7 6 4 3 2 1] without 5 there
		(1..9).each do |i|
			event = parsed[i-1].symbolize_keys
			if i < 6
				event[:id].should == 11-i
			else
				event[:id].should == 10-i
			end
		end
	end
   end

   describe "when user only has one event and he deletes that event" do
	it "should get the Example Event" do
		@request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
		@expected = {title: "Testing", start_time: 0100, end_time: 0200}
		subject.current_user.events.create(@expected)
		post :delete_event, :event_id => '1'
		response.body.should == [{id: '0', title: 'Example Event!', start_time: '1200', end_time: '1400'}].to_json
	end
   end

    ########TEST THE SUBMIT EVENT FUNCTIONS##########
    describe "user adds an event with the correct credentials" do
        it "should successfully display the event with the id, title, start_time, and end_time" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "testing", :start_time => 1200, :end_time => 1400
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.size.should == 1
            first_row = parsed.first.symbolize_keys
            first_row[:id].should == 1
            first_row[:title].should == "testing"
            first_row[:start_time].should == 1200
            first_row[:end_time].should == 1400
        end
    end

    #multiple events added
    describe "user adds many events with the correct credentials" do
        it "should successfully display events with the id, title, start_time, and end_time" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "testing", :start_time => 1200, :end_time => 1400
            post :submit_new_event, :title => "testing2", :start_time => 1400, :end_time => 1500
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.should == [{"id"=>1, "title"=>"testing", "start_time"=>1200, "end_time"=>1400}, 
                {"id"=>2, "title"=>"testing2", "start_time"=>1400, "end_time"=>1500}]
        end
    end

    #######TEST ERROR CODES FOR SUBMIT#######
    describe "user adds an event with an empty title" do
        it "should return an error that the input is invalid" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "", :start_time => 1200, :end_time => 1400
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.should == ["Invalid Input: Non-filled fields"]
        end
    end

    describe "user adds an event with an empty start_time" do
        it "should return an error that the input is invalid" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "testing1", :start_time => "", :end_time => 1400
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.should == ["Invalid Input: Non-filled fields", "Invalid Time: Start Time not correct format [hhmm]"]
        end
    end

    describe "user adds an event with an empty end_time" do
        it "should return an error that the input is invalid" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "testing1", :start_time => 1200, :end_time => ""
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.should == ["Invalid Input: Non-filled fields", "Invalid Time: End Time not correct format [hhmm]"]
        end
    end

    describe "user adds an event with a negative start_time" do
        it "should return an error that the input is invalid" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "testing1", :start_time => -1200, :end_time => 1400
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.should == ["Invalid Time: Seriously? Negative?", "Invalid Time: Start Time not correct format [hhmm]"]
        end
    end

    describe "user adds an event with a negative end_time" do
        it "should return an error that the input is invalid" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "testing1", :start_time => 1200, :end_time => -1400
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.should == ["Invalid Time: Seriously? Negative?", "Invalid Time: End Time not correct format [hhmm]"]
        end
    end

     describe "user adds an event with invalid 24 hour format" do
        it "should return an error that the input is invalid" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "testing1", :start_time => 200, :end_time => 1500
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.should == ["Invalid Time: Start Time not correct format [hhmm]"]
        end
    end

    describe "user adds an event with invalid 24 hour format" do
        it "should return an error that the input is invalid" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "testing1", :start_time => 1200, :end_time => 15000
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.should == ["Invalid Time: End Time not correct format [hhmm]"]
        end
    end


    describe "user adds an event with a very long title" do
        it "should return an error that the input is invalid" do
            @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(subject.current_user.email, "123")
            post :submit_new_event, :title => "testing1testing1testing1testing1testing1testing1
            testing1testing1testing1testing1testing1testing1testing1testing1
            testing1testing1testing1testing1testing1testing1testing1testing1testing1
            testing1testing1testing1testing1testing1testing1testing1testing1testing1
            testing1testing1testing1testing1testing1testing1", :start_time => 1200, :end_time => 1500
            parsed = ActiveSupport::JSON.decode(response.body)
            parsed.should == ["Invalid Title: More than 128 characters"]
        end
    end






=begin
    #ADD TWO USERS
    describe "should let server add two users with correct format" do
        it "should return SUCCESS" do
            User.delete_all
            new_User = User.new
            new_User.user = 'user1'
            new_User.save
            post :add, :user => "user2", :password => "pw", :format => :json
            response.body.should == {:errCode => 1, :count => 1}.to_json
        end
    end
    
    #USERNAME IS BLANK
    describe "should not let user create username if blank" do
        it "should return error -3" do
            expect { post :add, :user => "", :password => "hello", :format => :json }.to change(User, :count).by(0)
            response.body.should == {:errCode => -3}.to_json
        end
    end

    #DUPLICATE PASSWORDS ALLOWED
    describe "should let duplicate passwords" do
        it "should return SUCCESS" do
            User.delete_all
            new_User = User.new
            new_User.user = 'user1'
            new_User.password="pw"
            new_User.save
            post :add, :user => "user2", :password => "pw", :format => :json
            response.body.should == {:errCode => 1, :count => 1}.to_json
        end
    end

    #TOO MANY CHARACTERS: USERNAME
    describe "more than 128 characters not allowed for username" do
        it "should return error -3" do
            expect { post :add, :user => "lfjaeljriaejrlkjeakljrlkaejslkrjaklsjrkleasjklrjasljrlkajslrkjaslrjklasaehrlashrkjhaklhrahreahjrlasjrlkasjlrkjlasjrasljrkelsajahjfkgdahfjadhfhdakjfhkahflahfjahfkhgasjfgkdaygfhjgasjgejagfjasgfaegsfgajkfgaehjfgeahjksgfjegahfjgajsegfjekasgfjgakjgfakjgfjkgaejgfhjkaegsr", :password => "hello", :format => :json }.to change(User, :count).by(0)
            response.body.should == {:errCode => -3}.to_json
        end
    end

    #TOO MANY CHARACTERS: PASSWORD
    describe "more than 128 characters not allowed for password" do
        it "should return error -4" do
            expect { post :add, :user => "user1", :password => "lfjaeljriaejrlkjeakljrlkaejslkrjaklsjrkleasjklrjasljrlkajslrkjaslrjklasaehrlashrkjhaklhrahreahjrlasjrlkasjlrkjlasjrasljrkelsajahjfkgdahfjadhfhdakjfhkahflahfjahfkhgasjfgkdaygfhjgasjgejagfjasgfaegsfgajkfgaehjfgeahjksgfjegahfjgajsegfjekasgfjgakjgfakjgfjkgaejgfhjkaegsr", :format => :json }.to change(User, :count).by(0)
            response.body.should == {:errCode => -4}.to_json
        end
    end

    ########Test the login functions########
    
    #CORRECT LOGIN
    describe "should login and increment count" do
        it "should return SUCCESS" do
            User.delete_all
            new_User = User.new
            new_User.user = 'user1'
            new_User.password='pw'
            new_User.count = 1
            new_User.save
            post :login, :user => "user1", :password => "pw", :format => :json
            response.body.should == {:errCode => 1, :count => 2}.to_json
        end
    end

    #NEW USER
    describe "should not be able to login" do
        it "should return error -1" do
            User.delete_all
            post :login, :user => "user1", :password => "pw", :format => :json
            response.body.should == {:errCode => -1}.to_json
        end
    end
    
    #WRONG PASSWORD
    describe "should login and increment count" do
        it "should return error -4" do
            User.delete_all
            new_User = User.new
            new_User.user = 'user1'
            new_User.password='pw'
            new_User.count = 1
            new_User.save
            post :login, :user => "user1", :password => "wrong", :format => :json
            response.body.should == {:errCode => -4}.to_json
        end
    end
=end

end


