require "selenium-webdriver"
browser = Selenium::WebDriver.for :chrome
browser.get "http://tranquil-falls-5399.herokuapp.com/"
browser.find_element(link_text: "Sign up").click
p browser.current_url
p browser.title

##sign up##
browser.find_element(name: "user[email]").send_keys "user9955@schedule.com"
browser.find_element(name: "user[password]").send_keys "password"
browser.find_element(name: "user[password_confirmation]").send_keys "password"
browser.find_element(name: "commit").click
p browser.current_url
p browser.title

##create a schedule##
browser.find_element(name: "title").send_keys "schedule1"
browser.find_element(name: "start_time").send_keys "1200"
browser.find_element(name: "end_time").send_keys "2200"
browser.find_element(name: "commit").click
p browser.current_url
p browser.title


##create an event##
browser.find_element(name: "view").click
browser.find_element(name: "title").send_keys "event1"
browser.find_element(name: "start_time").send_keys "1200"
browser.find_element(name: "end_time").send_keys "1400"
browser.find_element(name: "address").send_keys "2020 Kittredge Ave. Berkeley, CA 94704"
browser.find_element(name: "commit").click
p browser.current_url
p browser.title


browser.close