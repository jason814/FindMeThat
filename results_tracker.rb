
class ResultsTracker
  PREVIOUS_MATCHES_FILE_NAME = "previous_matches.txt"
  SEPARATOR = "==="

  def initialize(url_base, search_term)
    @logger = Logging.logger[self]
    @sha1MapLogger = log  = Logging.logger("sha1_map_logger.log")

    @url_base = url_base
    @search_term = search_term
    @previous_matches_set = Set.new

    #    load_previous_matches(url_base, search_term)
  end

  def unreported_matches(reported_matches)
    if (reported_matches.length.nil?) 
      return Array.new()
    end
    
    existing_matching_set = load_previous_matches(reported_matches[0].parent.search_term, reported_matches[0].parent.base_url)
    unreported = Array.new


    @logger.debug "rt.unreported_matches.existing_matching_set: " + existing_matching_set.to_a.to_s
    reported_matches.each { |each|

      @logger.debug "Checking to see if : " + each.sha1_hash + " Is is in the existing set"

      if (!existing_matching_set.member? each.sha1_hash)
        unreported.push(each)
        @logger.debug "NEW ELEMENT  unreported: " + each.sha1_hash
        @logger.debug "NEW ELEMENT Description: " + each.description
        @sha1MapLogger.debug "Reported to have found a new Element: SHA1: " + each.sha1_hash
        @sha1MapLogger.debug "\n" + each.description.to_s
        @sha1MapLogger.debug each.html_piece.to_s
        @sha1MapLogger.debug ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .\n"

      else
        #@logger.debug "EXISTING ELEMENT : rs.unreported_matches.unreposrted " + each.description
        #@logger.debug "EXISTING ELEMENT rs.unreported_matches.unreported: " + each.html_piece.to_s

      end
    }
    @logger.debug "....."
    return unreported
  end

  def store_new_matches(matches_to_store)
    if matches_to_store.nil? 
      raise Exception.new " Emtpy array when trying to store...not really exception just debugging"
    end
    
    #@logger.debug "about to open the file"
    key = matches_to_store[0].parent.search_term + matches_to_store[0].parent.base_url
    #@logger.debug "key is: " + key
    begin
      existing_matching_set = load_previous_matches(matches_to_store[0].parent.search_term, matches_to_store[0].parent.base_url)
      #@logger.debug "existing Matching set: " + existing_matching_set.to_a.to_s


      first_time_this_time = true
      file = File.open(PREVIOUS_MATCHES_FILE_NAME, 'a')
      matches_to_store.each { |html_piece|
        begin
          @logger.debug "start" + html_piece.description
          if (!existing_matching_set.member? html_piece.sha1_hash)
            if (first_time_this_time)
              file.write("## date=#{Time.new.inspect}\n")
              first_time_this_time = false
            end
            key = html_piece.parent.search_term + html_piece.parent.base_url
            @logger.debug "key is: " + key
            key_value_pair = key + SEPARATOR + html_piece.sha1_hash + "\n"
            file.write(key_value_pair)
            @logger.debug "Wrote to file: " + key_value_pair
          else
            @logger.debug "didn't store the item to disk"
          end
        end
      }
        
    rescue IOError => e
      @logger.error "Caught Exception: " << e.message
      @logger.error "Caught Exception: " << e.backtrace.inspect
    rescue Exception => e
      @logger.error "Caught Exception: " <<  e.message
      @logger.error "Caught Exception: " << e.backtrace.inspect
    ensure
      file.close unless file == nil
      @logger.error "File is Closed"
    end

  end

  def load_previous_matches(url_base = "default", search_term = "none")
    keybase = url_base.to_s + search_term.to_s

    begin
      existing_matching_set = Set.new()
      File.open(PREVIOUS_MATCHES_FILE_NAME, 'r') { |infile|
        while (line = infile.gets)
          result = line.split(/===/)
          if (result[0] == keybase )
            existing_matching_set.add(result[1].gsub(/\n/, ''))
            #@logger.debug " Added entry to Previously matches: " +result[1]
          end
        end
      }
    rescue EOFError
      @logger.error "Got to end of the file"
    end
    return existing_matching_set
  end
end

