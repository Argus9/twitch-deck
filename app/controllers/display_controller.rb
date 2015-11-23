require 'net/http'

class DisplayController < ApplicationController
  # Render welcome message with how-to
  def index
  end
  
  def embed_streams
    # Parse parameters into all streamers.
    # ORDER MATTERS! The order in which a user inputs streamer names will 
    # determine who the "primary" streamer will be, and will affect ordering by 
    # the application when one goes offline.
    raise "Must pass at least one streamer as a parameter" if 
      params[ :streamers ].blank?
      
    @streamers = []
    
    params[ :streamers ].split( '/' ).each do | name |
      @streamers << { name: name, priority: @streamers.count, status: :offline }
    end
    
    # Use Twitch API to determine which streamers are online and which are
    # offline. Order the array of streamers based on online/offline status
    # first, then by priority as passed by the user.
    streamer_names = @streamers.map { | streamer | streamer[ :name ] }.join ',' 
    url = URI.parse("https://api.twitch.tv/kraken/streams?channel=#{ streamer_names }")
    req = Net::HTTP.new(url.host, url.port)
    req.use_ssl = true if url.scheme = "https"
    req.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = JSON.parse(req.get(url.request_uri).body)
    
    unless res[ 'streams' ].empty? # All streams are offline
      # Find all streamers in the list who are online.
      @streamers.each do | streamer |
        streamer[ :status ] = :online if res[ 'streams' ].select do | stream |
          stream[ 'channel' ][ 'name' ] == streamer[ :name ]
        end.present?
      end
    end
    
    # TODO: Once array is ordered, parse through it and create a stream for each
    # TODO: one.
    # TODO: MAKE SURE THERE IS A "PRIMARY" <div> THAT'S BIGGER THAN THE OTHERS!
    # render text: @streamers.select { | streamer | streamer.status == :online }
    render text: @streamers
  end
end
