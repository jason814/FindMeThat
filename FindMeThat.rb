#!/usr/bin/env ruby

require 'httpclient'
require 'mail'
require 'logging'

require_relative './HTMLParser'
require_relative './results_tracker.rb'

#
#logger = Logging.logger['MyLogger']
#logger.add_appenders(
#    Logging.appenders.stdout,
#    Logging.appenders.file('example.log')
#)


#Logging.logger.root.appenders = Logging.appenders.stdout
Logging.logger.root.appenders = [Logging.appenders.stdout, Logging.appenders.file('FindMeThat.log')]


Logging.logger['FindMeThat'].level = :debug
Logging.logger['results_tracker'].level = :debug
Logging.logger['HTMLParser'].level = :debug
Logging.logger['KslHtmlPiece'].level = :debug

$test_emails_only = false


class FindMeThat 
  attr_accessor :names
	attr_accessor :debug

  # Create the object
  def initialize(url, searchTerm, email_address = "jason814@gmail.com")
    @logger = Logging.logger[self]
		@names = "jason"
    @urlStr = url
		@searchTerm = searchTerm
    @email_address = email_address

		options = {
      :address              => "smtp.gmail.com",
      :port                 => 587,
      :domain               => 'gmail.com',
      :user_name            => 'jason814@gmail.com',
      :password             => 'BIGfish13',
      :authentication       => 'plain',
      :enable_starttls_auto => true
    }

		Mail.defaults do
  		delivery_method :smtp, options
		end

		@debug = true; 
  end

  #search fo the term given the URL
  def retrieve_html_content
    #raise ArgumentError, "url is uninitialized" unless @url.nil? false
    #raise ArgumentError, "search is uninitialized" unless @search.nil? false
		debug(@urlStr)

		client = HTTPClient.new
		return client.get_content(@urlStr)
	end

	def grep_for_term(htmlContent, reg_exp = @searchTerm)
		#@logger.info htmlContent
		debug("htmlContent Size: " + htmlContent.size.to_s)
		tmpMatch = htmlContent.match(@searchTerm)
		  	
		if (tmpMatch.nil? == false)
			debug "matched regEx on: " + tmpMatch.to_s
		else
			debug "no match :(" 
		end
		return tmpMatch
	end

	def send_email(email, subject, msg_body)
		begin
      Mail.deliver do
        from   'jason814@gmail.com'
        to     email
        subject subject
        body     msg_body
        #add_file '/full/path/to/somefile.png'
      end
		rescue Exception => e
	 		@logger.error "Exception occured: " + e.to_s
		end


		debug("sent email to: address: " + email)
    debug("      Email Subject: " + subject)
    debug("      Email Body   : " + msg_body.to_s)
	end

def find_unreported_matches(htmlStr)

    url_base = "https://www.ksl.com/index.php"
		html_parser = HTMLParser.new(htmlStr, url_base, @searchTerm)
    all_matches = html_parser.extract_html_pieces_from_ksl

    rt = ResultsTracker.new(url_base, @search_term)

    results = rt.unreported_matches(all_matches)
    @logger.info  "Unreported matches count is: " + results.size.to_s


    if (results.length > 0)

      @logger.info "results are: ...."
      results.each { |each| @logger.info each.description}
      @logger.info "end results....."


      self.notify_of_new_matches(results)
      rt.store_new_matches(results)
    end

    return results
  end



  def notify_of_new_matches(new_entries)
    #@logger.debug "Is it an array? " + new_entries.to_s
    email_body = ""
    if (new_entries.is_a?(Array) && new_entries.size > 1)
      email_subject = "Found " + new_entries.length.to_s + " matches to your search for:  " + new_entries[0].parent.search_term
      new_entries.each { |each|
        email_body += "new entry from search on ksl for: " + each.parent.search_term + "\r\n"
        email_body += each.description.to_s
        email_body += "\n . . . . . . . . . . . . . . . . . . . . . . . . . . . . \n"
      }
    else
      email_subject = "new entry from search on ksl for: " + new_entries[0].parent.search_term
      email_body = new_entries[0].description.to_s
    end
    if (!$test_emails_only)
        send_email(@email_address, email_subject, email_body)
    end
    send_email("jason814@gmail.com", "DEBUG: " + email_subject, email_body.to_s)

    if ($test_emails_only)
      @logger.info "!!!!!!!!!!!!!!ONLY SENDING TEST EMAIL TO JASON814@GMAIL.COM!!!!!!!!!"
      @logger.info("      Email Subject: " + email_subject)
      @logger.info("      Email Body   : " + email_body.to_s)
    else
      @logger.info "Sent Notification to #{@email_address} for #{email_subject} with subject: #{email_subject}"
    end
    

  end

	def debug(debugOutput)
		if (@debug) 
			@logger.debug debugOutput
		end
	end



	def search_html_page_for_term
		htmlContent =	retrieve_html_content
		hasMatch = grep_for_term(htmlContent)
	
		if !hasMatch.nil?
			@logger.debug "we have a winner folks...: \'" + @searchTerm + "\'"
		else
			@logger.debug "looser baby no match here on: \'" + @searchTerm + "\'"
		end
	end
	
end







if __FILE__ == $0

  log  = Logging.logger("FindMeThat.log")
  log.level = :debug
	test = false;

	if (test) 
		


  else
    $test_emails_only = false 
    
#    puts  " ============================================================================="
#    puts  " ============================================================================="
#    puts " ============================================================================="
#    #    url = "http://www.woot.com"
#    url = "https://www.ksl.com/index.php?nid=231&sid=74268&cat=&search=white+crib&zip=Enter+Zip+Code&distance=&min_price=&max_price=&type=&category=&subcat=&sold=&city=&addisplay=&sort=5&userid=&markettype=sale&adsstate=&nocache=1&o_facetSelected=&o_facetKey=&o_facetVal=&viewSelect=list&viewNumResults=12&sort=5"
# 		fmt = FindMeThat.new(url, "white Crib")#, "8014040864@tmomail.net") #include Email
#		htmlStr = fmt.retrieve_html_content
#		fmt.find_unreported_matches htmlStr
#
#    puts  " ============================================================================="
#    puts  " ============================================================================="
#    puts " ============================================================================="
#    url = "https://www.ksl.com/index.php?nid=231&sid=74268&cat=&search=Gun&zip=&distance=&min_price=&max_price=&type=&category=353&subcat=&sold=&city=&addisplay=&sort=5&userid=&markettype=sale&adsstate=&nocache=1&o_facetSelected=&o_facetKey=&o_facetVal=&viewSelect=list&viewNumResults=12&sort=1"
#    search_term = "gun"
#    fmt = FindMeThat.new(url, search_term)#, "8014040864@tmomail.net") #include Email
#		htmlStr = fmt.retrieve_html_content
#		fmt.find_unreported_matches htmlStr

#    log.debug " ============================================================================="
#    log.debug " ============================================================================="
#    log.debug " ============================================================================="
#....................Commented out 5/4/2013
 #   url = "https://www.ksl.com/index.php?nid=231&sid=74268&cat=438&search=toro+propelled&zip=Enter+Zip+Code&distance=&min_price=75&max_price=400&type=&category=51&subcat=&sold=&city=&addisplay=&sort=1&userid=&markettype=sale&adsstate=&nocache=1&o_facetSelected=&o_facetKey=&o_facetVal=&viewSelect=list&viewNumResults=12&sort=1"
#    search_term = "toro propelled"
#    fmt = FindMeThat.new(url, search_term, "jmartin127@gmail.com") #include Email
#		htmlStr = fmt.retrieve_html_content
#		fmt.find_unreported_matches htmlStr

  #  log.debug " ============================================================================="
#    log.debug " ============================================================================="
#    log.debug " ============================================================================="

    
#    url = "https://www.ksl.com/index.php?nid=231&sid=74268&cat=473&search=%22hand+gun%22+safe&zip=Enter+Zip+Code&distance=&min_price=&max_price=&type=&category=353&subcat=&sold=&city=&addisplay=&sort=1&userid=&markettype=sale&adsstate=&nocache=1&o_facetSelected=&o_facetKey=&o_facetVal=&viewSelect=list&viewNumResults=12&sort=1"
#    search_term = "\"hand gun\" safe"
 #   fmt = FindMeThat.new(url, search_term, "jason814@gmail.com") #include Email
#		htmlStr = fmt.retrieve_html_content
#		fmt.find_unreported_matches htmlStr

    log.debug " ============================================================================="
    log.debug " ============================================================================="
    log.debug " ============================================================================="
url = "http://www.ksl.com/index.php?nid=231&sid=74268&cat=215&search=&zip=&distance=&min_price=60&max_price=120&type=&category=16&subcat=&sold=&city=&addisplay=&sort=1&userid=&markettype=sale&adsstate=&nocache=1&o_facetSelected=&o_facetKey=&o_facetVal=&viewSelect=list&viewNumResults=12&sort=1" 
    search_term = "Elisabeth Laptop: Cost 60-120"
    fmt = FindMeThat.new(url, search_term, "jason814@gmail.com") #include Email
		htmlStr = fmt.retrieve_html_content
		fmt.find_unreported_matches htmlStr

    log.debug " ============================================================================="
    log.debug " ============================================================================="
    log.debug " ============================================================================="

url = "http://www.ksl.com/auto/search/index?o_facetClicked=true&o_facetValue=1000%2C70000&o_facetKey=mileageFrom%2C+mileageTo&resetPage=true&keyword=&make[]=Dodge&model[]=Ram+1500&yearFrom=&yearTo=&priceFrom=&priceTo=&mileageFrom=1000&mileageTo=70000&zip=&miles=0"
    search_term = "Dodge 1/4 Ton Truck Search for Alan"
    fmt = FindMeThat.new(url, search_term, "Strange1utah@yahoo.com") #include Email
		htmlStr = fmt.retrieve_html_content
		fmt.find_unreported_matches htmlStr

    log.debug " ============================================================================="
    log.debug " ============================================================================="
    log.debug " ============================================================================="

url = "http://www.ksl.com/index.php?sid=5017903&nid=651&area=&zoom=&centerPoint=&page_type=&new_zip=&zip_name=&sale=1&type=1&city=Highland&zipcode=&distance=&state=0&start=380000&end=500000&keyword=&sellertype=&acresstart=&acresend=&homes_search=Search&sqftstart=&sqftend=&bedrooms=&bathrooms="
    search_term = "Homes in highland 350-500"
    fmt = FindMeThat.new(url, search_term, "kristine814@hotmail.com") #include Email
		htmlStr = fmt.retrieve_html_content
		fmt.find_unreported_matches htmlStr

    log.debug " ============================================================================="
    log.debug " ============================================================================="
    log.debug " ============================================================================="



	end
end


