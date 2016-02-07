require 'net/http'

class DisplayController < ApplicationController
	# Render welcome message with how-to
	def index
	end

	def embed_streams
		# Parse parameters into all streamers.
		# ORDER MATTERS! The order in which a user inputs streamer names will determine who the "primary" streamer will be,
		# and will affect ordering by the application when one goes offline.
		raise 'Must pass at least one streamer as a parameter' if params['streamers'].blank?

		@streamers = []

		params['streamers'].downcase.split('&').each do |name|
			@streamers << { 'name' => name, 'priority' => @streamers.count, 'status' => 'offline' } unless @streamers.select { |streamer| streamer['name'] == name }.present?
		end

		# Use Twitch API to determine which streamers are online and which are
		# offline. Order the array of streamers based on online/offline status
		# first, then by priority as passed by the user.
		status = JSON.parse make_request 'https://api.twitch.tv/kraken/streams?channel='\
            "#{ @streamers.map { |streamer| streamer['name'] }.join ',' }"
		unless status['streams'].empty? # All streams are offline
			@streamers.each do |streamer|
				# The channel name will only be present if it's online.
				streamer['status'] = status['streams'].select do |stream|
					stream['channel']['name'] == streamer['name']
				end.present? ? 'online' : 'offline'
			end
		end

		# Once we know which streams are online, sort them based on online status, then by priority.
		@streamers.sort_by! { |streamer| [streamer['status'] == 'online' ? 0 : 1, streamer['priority']] }
		session['streamers'] = @streamers.to_json

		# We are now ready to use the +@streamers+ Array to render streams in the view! Save the @streamers to the
		# session.
	rescue SocketError
		render status: 500, text: 'Unable to connect to Twitch API.'
	end

	##
	# Calls +embed_streams+ with a pre-set list of streamers.
	def demo
		redirect_to %w(/day9tv kinggothalion professorbroman covert_muffin totalbiscuit man_vs_game trumpetmcool ).join '&'
	end

	private

	##
	# Helper method that makes an HTTP GET request and returns the response body.
	# @param url [String] The URL to send the request to.
	# @return [String] The response body.
	def make_request url
		uri = URI.parse url
		req = Net::HTTP.new uri.host, uri.port
		req.use_ssl = true if uri.scheme == 'https'
		req.verify_mode = OpenSSL::SSL::VERIFY_NONE

		req.get(uri.request_uri).body
	end
end
