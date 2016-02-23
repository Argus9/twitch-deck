class RedirectorController < ApplicationController
    def redirect
        @streamer = params[:streamer]
    end
end
