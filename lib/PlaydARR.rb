require 'rubygems'
require 'httparty'

# Playdar! A music resolver, now accessible from Ruby
#
# The basics are here, try this:
#
#     PlaydARR::Server.search("Air","Sexy Boy").each do |track|
#       p track
#       puts track.resolve_uri
#     end
module PlaydARR
  
  # Class that represents a track, as returned from the Server.
  class Track
    attr_reader :duration, :size, :sid, :url, :bitrate, :mimetype, :source
    attr_reader :artist, :album, :track
    attr_reader :score, :preference, :resolve_uri
    # Expects a Hash in the form delivered by the Playdar server
    #
    # Example:
    #     {
    #       "duration"=>188,
    #       "artist"=>"The Prodigy",
    #       "size"=>5199064,
    #       "track"=>"Omen",
    #       "sid"=>"232c123f-ae1a-43c2-88b7-becddbc9de08",
    #       "url"=>"file:///…/1-01 Omen.mp3",
    #       "bitrate"=>221,
    #       "album"=>"Addicted To Bass",
    #       "mimetype"=>"audio/mpeg",
    #       "source"=>"Your Playdar Source",
    #       "score"=>1.0,
    #       "preference"=>100
    #     }
    def initialize(track)
      track.each do |key,value|
        eval("@#{key} = \"#{value}\"")
      end
      @resolve_uri = "http://#{Server::Address}:#{Server::Port}/sid/#{@sid}"
    end
    
    # A quick indication of what the track is, for inspection
    def inspect
      "#{@artist}: #{@track} (#{@album})"
    end
  end
  
  # Used to access the Playdar server
  class Server
    Address = "127.0.0.1"
    Port = 60210
    
    include HTTParty
    base_uri "#{Address}:#{Port}/api"
    format :json

    # Gets the stats of the server. Notably it can be used to find the server version and whether
    # a playdar server is actually running.
    def self.stats
      get('?method=stat')
    end
  
    # Search the Playdar database for a particular song
    # Album isn't required, but its suggested!
    def self.search(artist, track, album = "")
      # TODO: specify my own QID to speed up the process?
      begin
        qid = get('',
          :query => q = {
            :method => "resolve",
            :artist => artist,
            :album => album,
            :track => track
          }
        )['qid']
      rescue Crack::ParseError # I think playdar doesn't send a nice response when there's no results?
        return []
      end  
        
      res = nil
      0.upto(6) do
        res = get('',
          :query => {
            :method => "get_results",
            :qid => qid
          }
        )
        break if res['query']['solved']
        # This pause will respect the time suggested by playdar when that feature is implemented
        sleep(0.1)
      end
      res['results'].collect{|track| Track.new(track)}
    end
  end
end