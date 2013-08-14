#!/usr/bin/env ruby

#require 'nokogiri'
require "rexml/document"
require "hpricot" # need hpricot and open-uri
 require "open-uri"
 require 'digest/sha1'




class HTMLParser

	attr_accessor :htmlStr
	attr_accessor :debug
  attr_accessor :html_pieces
  attr_accessor :search_term
  attr_accessor :base_url

	def initialize(htmlStr, page_root, search_term)
    @logger = Logging.logger[self]
		@htmlStr = htmlStr
    @page_root = @base_url = page_root
    @search_term = search_term
    @html_pieces = Array.new(0)

		@debug = true


    parse_html htmlStr




	end

  def parse_html(htmlStr)
    begin
			debug @htmlStr[0..100]
      # load the Family guy's home page
      @doc = Hpricot(@htmlStr )

		rescue Exception => e
			#For some reason this just disappeared...no idea of the reason why!!!
			@logger.info  "Got a runtime error attempting to turn the HTML response into a DOM"
			#puts RuntimeError.instance_methods
			#puts e.instance_variables
			puts e.to_s
			puts "Lenghth: " <<	@htmlStr.size.to_s
       #      errorLocation = get_position_location( e.message).to_i
       #      puts "error location: " << errorLocation
       #			puts "contents around error area: " <<  @htmlStr[(errorLocation - 50)..(errorLocation+50)]
			return
		end
    @logger.error   "Successfully parsed the html"
  end


  def get_page_root
    return @page_root
  end

	def sanitize(htmlStr)
		result =  htmlStr.gsub(/<link.*.\/>/, '<Replaced/>').
                      gsub(/<script.*<\/script>/,'<replacedSCRIPT1/>').
                      gsub(/<script>.+?<\/script>/m,'<replacedSCRIPT/>').
                      gsub(/\r/, '').gsub(/\n/, '').
                      #gsub(/<a href=.*<\/a>/, '<replacedHREF/>').
                      #gsub(/&#\d+;/, 'blah')
                      #htmlStr.gsub(/&/,' ').gsub(/[\n\r]/,'')
    #debug result
    return result

	end

  def get_position_location(e)
    e.to_s =~ /Position: (\d+)/
    @logger.info   "position value: " + $1
    if $1.nil?
      throw Exception "unable to find position value in exception"
    end

    return $1
  end

	def strip_unneeded_elements

		begin
			debug @htmlStr[0..100]
      # load the Family guy's home page
      doc = Hpricot(@htmlStr )

		rescue Exception => e 
			#For some reason this just disappeared...no idea of the reason why!!!
			@logger.info   "Got a runtime error attempting to turn the HTML response into a DOM"
			#puts RuntimeError.instance_methods
			#puts e.instance_variables
			@logger.error e.to_s
			@logger.error "Lenghth: " <<	@htmlStr.size.to_s
       #      errorLocation = get_position_location( e.message).to_i
       #      @logger.error "error location: " << errorLocation
       #			@logger.error "contents around error area: " <<  @htmlStr[(errorLocation - 50)..(errorLocation+50)]
			return
		end 

		@logger.info "Successfully turned HTML response into a DOM"
		#debug("# of nodes in HTML Doc: " + @doc.length)

    doc.search("//link").remove
    doc.search("//meta").remove
    doc.search("//script").remove
    #debug doc.to_s
    @doc = doc
    return doc
#		debug("Node list: " + @doc.inspect)
	end

  def extract_html_pieces_from_ksl
    
    @logger.debug "extract_html_piece_from_ksl - Start"
    datas = @doc.search("//div[@class='detailBox']")
    if datas.nil? 
      throw Exception.new "Unable to extract requested data"
    end

    count = 1
    datas.each() { |data|
      begin

        @logger.debug "Count: " + (count += 1).to_s
        @logger.debug "data" << data.to_s
        ksl_piece = KslHtmlPiece.new(data, self)
        @html_pieces.push(ksl_piece)
        @logger.debug ksl_piece.description
        
      end
    }
    @logger.info "Size of HTML Pieces: " + @html_pieces.size.to_s
    @logger.info @html_pieces.to_s
    return @html_pieces.to_ary
  end

  def print_html_pieces
      @html_pieces.each { |each|
      @logger.info "each: " + each.description
      @logger.info ". . . . . . . . . . . . . . . . . . . . . ., . . . . . . .  "
    }

  end

	def debug(debugOutput)
		if (@debug) 
			@logger.debug debugOutput
		end
	end


end



class KslHtmlPiece
  attr_accessor :parent
  attr_accessor :sha1_hash
  attr_accessor :html_piece

  def initialize (html_piece, parent)
    @logger = Logging.logger[self]
    @html_piece = html_piece
    @parent = parent
  end

  def get_link
    result =  @parent.get_page_root + @html_piece.at("a.listlink").attributes["href"].to_s
    #result = str.gsub(/&ad_cid=\d/, '')
    return result
  end

  def get_title
    title_html = @html_piece.at("a.listlink")
    return fix_fix_result_str title_html.inner_text.to_s
  end

  def get_town
    return fix_fix_result_str @html_piece.at("div.adTime > span").innerHTML.to_s
  end
  
  def get_description
    step1 = @html_piece.at("div.adDesc")
    step2 = step1.search("a.listlink")
    if !step2.nil?
      step2.remove
    end
    return fix_fix_result_str step1.innerHTML.to_s
  end

  def get_price
    step1 = @html_piece.at("div.priceBox")
    step2 = step1.search("a > span > span.priceCents")
    if !step2.nil?
      step2.remove
    end
    return fix_fix_result_str("~" + step1.inner_text)
  end

  def get_days_listed
    day_element=  @html_piece.at("div.adTime")
    match = day_element.to_s.match(/\d+ (Day|Day|Minutes)/)
    
    return match.to_s
  end


  def fix_fix_result_str (raw_str)
    step1 = raw_str#raw_str.squeeze
    #step2 =  step1.gsub(/^[\d\a\s]/, '')
    step3 = step1.gsub(/&nbsp;/, ' ')
    step4 = step3.gsub(/[\r\n]/, '')
    return step4
  end

  def description
   # @logger.debug @html_piece.to_s
    resultstr =  "Title: " << get_title << "\n"
    resultstr << "Description: " << get_description << "\n"
    resultstr << "Price: " << get_price << "\n"
    resultstr << "Town: " << get_town << "\n"
    resultstr << "Listed: " << get_days_listed << "\n"
    resultstr << "Link: " << get_link << "\n"
    resultstr << "SHA1: " << sha1_hash << "\n"
    return resultstr
  end


  def sha1_hash
    if @sha1_hash.nil?
      summaryStr = get_price + get_title + get_town + get_description
      @sha1_hash = Digest::SHA1.hexdigest(summaryStr.to_s)
    end
    @sha1_hash
  end
end


class HTMLPiece

  def initialize(search_term, html_sub_str)
    @search_term = search_term
    @html_sub_str = html_sub_search_term  
  end

  def intialize(matchdatas, htmlstr, search_term)


  end

  def to_s
    return "Search Term: '" << @search_term << "' html piece '" + @html_sub_str + "'"
  end

  def hash
    hash_base = @search_term + @html_sub_str
    return hash_base.hash.to_s

  end

end

