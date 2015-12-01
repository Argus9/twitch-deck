require 'logger'

class TwitchDeckLogger < Logger
    def format_message severity, timestamp, _, msg
        # noinspection RubyResolve
        "<#{ timestamp }> [#{ severity }] #{ msg }\n".send( case severity
                                                                when 'DEBUG'
                                                                    # noinspection RubyResolve
                                                                    :green
                                                                when 'WARN'
                                                                    # noinspection RubyResolve
                                                                    :yellow
                                                                when 'ERROR'
                                                                    # noinspection RubyResolve
                                                                    :red
                                                                else
                                                                    :white
                                                            end ).on_black
    end
end