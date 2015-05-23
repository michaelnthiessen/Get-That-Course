require 'mechanize'
require 'nokogiri'
require 'pg'
require 'sequel'
require 'mail'
require 'sinatra'

AURORA_LOGIN = 'https://aurora.umanitoba.ca/banprod/twbkwbis.P_WWWLogin'

class Scraper

    def initialize

        # Connect to our database
        database = Sequel.connect(ENV['DATABASE_URL'])
        @sections = database.from(:sections)
        @track = database.from(:track)

        options = { :address              => "mail.hover.com",
                    :port                 => 587,
                    :domain               => 'www.getthatcourse.com',
                    :user_name            => 'michael@getthatcourse.com',
                    :password             => '123Ilovethee',
                    :authentication       => 'plain',
                    :enable_starttls_auto => true }

        Mail.defaults do
          delivery_method :smtp, options
        end

        $stdout.sync = true

    end

    def start

        # Do our scraping
        scrape

        # Determine if anyone needs to be notified
        notify_list = find_openings

        # Send notifications
        send_notifications notify_list

    end

    def send_notifications notify_list

        # Send emails to each person
        notify_list.each do |n|

            # Get the title of the course
            course = @sections.where(:crn => n[:crn]).first

            puts "Sending an email to #{n[:email]}"

            # Create and send the email
            mail = Mail.new do
                from 'Get That Course <michael@getthatcourse.com>'
                to n[:email]
                subject "#{course[:title]} has opened up!"

                # Use HTML to add in some better formatting
                html_part do
                    content_type 'text/html; charset=UTF-8'
                    body    "We have found an opening for you in:<br><br>" +
                            "#{course[:title]}<br>#{course[:subject]} #{course[:course]}<br>#{course[:crn]}<br>#{course[:section]}<br><br>" +
                            "There are only <strong>#{course[:spots_left]}</strong> spots left, so hurry up and register before it fills up again!<br>" +
                            "<a href='#{AURORA_LOGIN}'>Aurora Login</a>"
                end
            end

            mail.deliver
        end
    end

    def find_openings

        # Select all records that haven't been notified the previous time
        not_open = @track.where(:open => false)

        # Put all of those CRN's and emails into arrays
        not_open_courses = []
        not_open.each do |s|
            not_open_courses << {:crn => s[:crn], :email => s[:email]}
        end

        # Update all of the sections that we are tracking
        @track.all.each do |s|

            course = @sections.where(:crn => s[:crn]).first

            # Update our course
            if (course[:spots_left] > 0)
                @track.where(:crn => s[:crn]).update(:open => true)
            else
                @track.where(:crn => s[:crn]).update(:open => false)
            end

        end

        # Find all of the ones that changed from not open to open and notify!
        notify_list = []
        not_open_courses.each do |c|
            course = @track.where(:crn => c[:crn], :email => c[:email], :open => true)
            if (course.count > 0)
                puts "Notify #{c[:email]} that #{c[:crn]} has opened up!"
                notify_list << c
            end
        end

        # Return the list of notifications that need to be made
        notify_list

    end

    def scrape
        puts '====== Started scraping ====='

        agent = Mechanize.new
        agent.read_timeout = 180
        agent.open_timeout = 180
        agent.user_agent_alias = 'Mac Safari'

        loginPage = agent.get(AURORA_LOGIN)
        print_page_title loginPage

        # Login to the site
        form = loginPage.forms.first
        form['sid'] = '7705906'
        form['PIN'] = '123iloveth'
        insidePage = form.click_button(form.buttons.first)

        # Handle the redirection
        metaRefresh = insidePage.search('meta').first.attributes
        redirectURL = metaRefresh['content'].to_s.split(';')[1].match(/=(.*)/)[1]

        puts "Redirecting to #{redirectURL}"

        insidePage = agent.get("https://aurora.umanitoba.ca" + redirectURL)

        # Click through some links
        insidePage = agent.click(insidePage.link_with(:text => /Enrolment & Academic Records/))
        insidePage = agent.click(insidePage.link_with(:text => /Registration/))
        insidePage = agent.click(insidePage.link_with(:text => /Look Up Classes/))

        # Select our term
        form = insidePage.forms.first
        selectList = form.fields[1]
        selectList.value = selectList.options[2].value
        insidePage = form.submit

        # Go the advanced search
        form = insidePage.forms.first
        button = form.buttons_with(:value => /Advanced Search/)
        advancedSearch = form.click_button(button[0])
        print_page_title advancedSearch

        # Select our form
        form = advancedSearch.forms.first

        # Search
        puts 'Submitting Advanced Search form...'
        results = form.click_button(form.buttons_with(:value => 'Class Search')[0])

        # Parse the sections out
        parseSections results

        puts '====== Finished scraping ====='

    end

    def parseSections results

        results = results.search('table.datadisplaytable')
        results = results.search('tr')

        results.each do |section|

            section = section.search('td')

            if section.size == 17 && section[1].inner_text.strip.to_i != 0

                # Store the details of the section
                temp = []
                section.each_with_index do |detail, i|
                    temp << section[i].inner_text.strip
                end

                # Convert everything into a hash for convenience
                d = {
                    :crn => temp[1],
                    :subject => temp[2],
                    :course => temp[3],
                    :section => temp[4],
                    :credits => temp[6],
                    :title => temp[7],
                    :days => temp[8],
                    :time => temp[9],
                    :total_spots => temp[10],
                    :spots_filled => temp[11],
                    :spots_left => temp[12],
                    :instructor => temp[13],
                    :date => temp[14],
                    :location => temp[15]
                }

                # puts '==================================='

                # puts "CRN: '#{d[:crn]}'"
                # puts "Subject: #{d[:subject]}"
                # puts "Course: #{d[:course]}"
                # puts "Section: #{d[:section]}"
                # puts "Title: #{d[:title]}"
                # puts "Total Spots: #{d[:capacity]}"
                # puts "Spots Left: #{d[:spots_left]}"

                # Update this section in the database
                updateSectionInDatabase d
            end
        end

    end

    # Update a section in the database, or add a new record if needed
    def updateSectionInDatabase d

        # Create a new record if we need to
        if @sections.where(:crn => d[:crn]).count == 0
            @sections.insert(
                :crn => d[:crn],
                :subject => d[:subject],
                :course => d[:course],
                :section => d[:section],
                :title => d[:title],
                :total_spots => d[:total_spots].to_i,
                :spots_left => d[:spots_left].to_i
            )

            puts "Inserting #{d[:crn]} - #{d[:title]} into the database"

        # Otherwise we update the existing record
        else
            @sections.where(:crn => d[:crn]).update(
                :subject => d[:subject],
                :course => d[:course],
                :section => d[:section],
                :title => d[:title],
                :total_spots => d[:total_spots].to_i,
                :spots_left => d[:spots_left].to_i
            )

            puts "Updating #{d[:crn]} - #{d[:title]}"
        end

    end

    def print_page_title page
        puts "Title of page: #{page.search('title').first.inner_text}"
    end

end

Scraper.new.start








