require 'net/http'

class DisplayController < ApplicationController
	# Render welcome message with how-to
	def index
	end

	def embed_streams
		# Parse parameters into all streamers.
		# ORDER MATTERS! The order in which a user inputs streamer names will determine who the "primary" streamer will be,
		# and will affect ordering by the application when one goes offline.
		raise 'Must pass at least one streamer as a parameter' if params[ :streamers ].blank?

		@streamers = []

		params[ :streamers ].split( '/' ).each do | name |
			@streamers << { name: name, priority: @streamers.count, status: :offline } unless
                @streamers.select{ | streamer | streamer[ :name ] == name }.present?
		end

		status = poll_twitch_for_streams
        update_stream_online_status status unless status[ 'streams' ].empty? # All streams are offline

		# Once we know which streams are online, sort them based on online status, preserving the order given by the
		# user.
		online_streamers = @streamers.select { | streamer | streamer[ :status ] == :online }
		offline_streamers = @streamers.select { | streamer | streamer[ :status ] == :offline }
		@streamers = online_streamers + offline_streamers

		# We are now ready to use the +@streamers+ Array to render streams in the view!
        session[ :streamers ] = @streamers.to_json
    rescue SocketError
        render status: 500, text: 'Unable to connect to Twitch API.'
	end

    ##
    # Sets +@streamers+ to a pre-defined set of streamers and renders the TwitchDeck page. Useful for testing purposes.
	def demo
		@streamers = [ { name: 'day9tv', priority: 0, status: :offline },
                       { name: 'kinggothalion', priority: 1, status: :offline },
                       { name: 'professorbroman', priority: 2, status: :offline },
                       { name: 'covert_muffin', priority: 3, status: :offline },
                       { name: 'man_vs_game', priority: 4, status: :offline },
                       { name: 'trumpetmcool', priority: 5, status: :offline } ]
        session[ :streamers ] = @streamers.to_json
        render :embed_streams
    end

    ##
    # Queries the Twitch API to see if the main player's channel is online.
    # @return [Boolean] `true` if the stream is online, `false` if it's not.
    def is_main_stream_online
        @streamers = JSON.parse session[ :streamers ]
        response = JSON.parse make_request "https://api.twitch.tv/kraken/streams/#{ @streamers.first[ :name ] }"
        if response[ 'stream' ].present?
            render :nothing
        else
            render js: 'location.reload()'
        end
    end

    ##
    # Checks the status of all streamers and updates priorities. The Javascript in the view will update the page layout
    # according to the changing priorities.
    # @return Hash +@streamers+ as a JSON Hash.
    def update_streams
        status = poll_twitch_for_streams
        update_stream_online_status status unless status[ 'streams' ].empty?

        # Finally, re-order the streamers by online status and priority, then update priorities on all streams.
        @streamers.sort_by! { | streamer | [ streamer[ :status ] == :online ? 0 : 1, streamer[ :priority ] ] }
        @streamers.each_with_index { | streamer, index | streamer[ :priority ] = index }

        render json: @streamers
    rescue SocketError
        render json: {}
    end

    private

    ##
    # Get the status of all streamers currently in +@streamers+.
    # @return [Hash] JSON Hash containing streamer info, delivered from Twitch.
    def poll_twitch_for_streams
        # Use Twitch API to determine which streamers are online and which are
        # offline. Order the array of streamers based on online/offline status
        # first, then by priority as passed by the user.
        streamer_names  = @streamers.map { | streamer | streamer[ :name ] }.join ','
        JSON.parse make_request "https://api.twitch.tv/kraken/streams?channel=#{ streamer_names }"
    end

    ##
    # Find all streamers in the list who are online.
    # @param json [Hash] The JSON response from the Twitch API call in +poll_twitch_for_streams+.
    def update_stream_online_status json
        @streamers.each do | streamer |
            # The channel name will only be present if it's online.
            streamer[ :status ] = :online if json[ 'streams' ].select do | stream |
                stream[ 'channel' ][ 'name' ] == streamer[ :name ]
            end.present?
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
