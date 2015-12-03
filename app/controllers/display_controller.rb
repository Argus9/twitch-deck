require 'net/http'

class DisplayController < ApplicationController
	# Render welcome message with how-to
	def index
	end

	def embed_streams
		# Parse parameters into all streamers.
		# ORDER MATTERS! The order in which a user inputs streamer names will determine who the "primary" streamer will be,
		# and will affect ordering by the application when one goes offline.
		raise 'Must pass at least one streamer as a parameter' if params[ 'streamers' ].blank?

		@streamers = []

		params[ 'streamers' ].downcase.split( '&' ).each do | name |
			@streamers << { 'name' => name, 'priority' => @streamers.count, 'status' => 'offline' } unless
                @streamers.select{ | streamer | streamer[ 'name' ] == name }.present?
		end

		status = poll_twitch_for_streams
        update_stream_online_status status unless status[ 'streams' ].empty? # All streams are offline

		# Once we know which streams are online, sort them based on online status, then by priority.
		sort_streamers

		# We are now ready to use the +@streamers+ Array to render streams in the view! Save the @streamers to the
		# session.
        session[ 'streamers' ] = @streamers.to_json
    rescue SocketError
        render status: 500, text: 'Unable to connect to Twitch API.'
	end

    ##
    # Calls +embed_streams+ with a pre-set list of streamers.
	def demo
        redirect_to %w(/day9tv kinggothalion professorbroman covert_muffin totalbiscuit man_vs_game trumpetmcool ).join '&'
    end

    ##
    # Queries the Twitch API to see if the main player's channel is online. If it isn't, reload the page. Otherwise,
	# render nothing (covers the case where the main stream is online or all streams are offline)
    def are_streams_online
	    @streamers = JSON.parse session[ 'streamers' ]

	    update_streams

	    # Get all online streamers.
	    online_streamers = @streamers.select { | streamer | streamer[ 'status' ] == 'online' }
	    # Compare their priorities. Is the stream with the highest priority in the main player?
	    highest_priority_online_streamer = online_streamers.min_by { | streamer | streamer[ 'priority' ] }

	    main_streamer = @streamers.first
	    sort_streamers

	    if @streamers.all? { | streamer | streamer[ 'status' ] == 'offline' }
			logger.info 'All streamers are offline - doing nothing'
			render nothing: true
	    elsif main_streamer[ 'name' ] != highest_priority_online_streamer[ 'name' ]
			logger.info 'Higher-priority streamer came online - reorder streamers'
			render js: %(replace_streamers( '#{ @streamers.map { | streamer | streamer[ 'name' ] }.to_json }');)
	    elsif main_streamer[ 'status' ] == 'online'
			logger.info 'Main stream is online - doing nothing'
	        render nothing: true
        elsif main_streamer[ 'status' ] == 'offline'
			logger.info 'Main streamer is offline - reorder streamers'
			render js: %(replace_streamers( '#{ @streamers.map { | streamer | streamer[ 'name' ] }.to_json }');)
        else
			logger.warn '`are_streams_online` default option - should not get here! May indicate a code problem'
			render nothing: true
        end
    end

    def replace_main_stream
        @streamers = JSON.parse session[ 'streamers' ]

        @streamers.delete_if { | streamer | streamer[ 'name' ] == params[ :streamer ] }
        @streamers.unshift( { 'name' => params[ 'streamer' ] } )
        session[ 'streamers' ] = @streamers.to_json

        redirect_to '/' + @streamers.map { | streamer | streamer[ 'name' ] }.join( '&' )
	    # TODO: Find some way to use js-side "replace_streamers" function, like we do above.
    rescue SocketError
		# noop
    end

    private

    ##
    # Checks the status of all streamers and updates priorities. The Javascript in the view will update the page layout
    # according to the changing priorities.
	def update_streams
		status = poll_twitch_for_streams
		update_stream_online_status status unless status[ 'streams' ].empty?
	rescue SocketError
		logger.warn 'Could not poll Twitch APIs due to connection error'
	end

	##
    # Sorts the streamers by online status and priority, then updates priorities on all streams.
	def sort_streamers
		@streamers.sort_by! { | streamer | [ streamer[ 'status' ] == 'online' ? 0 : 1, streamer[ 'priority' ] ] }
		session[ 'streamers' ] = @streamers.to_json
	end

    ##
    # Get the status of all streamers currently in +@streamers+.
    # @return [Hash] JSON Hash containing streamer info, delivered from Twitch.
    def poll_twitch_for_streams
        # Use Twitch API to determine which streamers are online and which are
        # offline. Order the array of streamers based on online/offline status
        # first, then by priority as passed by the user.
        streamer_names  = @streamers.map { | streamer | streamer[ 'name' ] }.join ','
        JSON.parse make_request "https://api.twitch.tv/kraken/streams?channel=#{ streamer_names }"
    end

    ##
    # Find all streamers in the list who are online.
    # @param json [Hash] The JSON response from the Twitch API call in +poll_twitch_for_streams+.
    def update_stream_online_status json
        @streamers.each do | streamer |
            # The channel name will only be present if it's online.
            streamer[ 'status' ] = json[ 'streams' ].select do | stream |
                stream[ 'channel' ][ 'name' ] == streamer[ 'name' ]
            end.present? ? 'online' : 'offline'
        end
    end

    ##
    # Helper method that makes an HTTP GET request and returns the response body.
    # @param url [String] The URL to send the request to.
    # @return [String] The response body.
    def make_request url
        uri = URI.parse url
        req = Net::HTTP.new uri.host, uri.port
        req.use_ssl = true if uri.scheme == 'https'
        req.verify_mode = OpenSSL::SSL::VERIFY_NONE

        req.get( uri.request_uri ).body
    end
end
