var initialize_stream_manager = function ( json_string ) {
    var streamers = JSON.parse( json_string );

    /*
     * Update streams on the page, based on their online status.
     */
    var get_stream_status = function () {
        /*
         * Callback that follows a successful AJAX call to Twitch's API.
         */
        var callback_function = function ( callback_data ) {
            $.each( streamers, function ( _, streamer ) {
                streamer[ 'status' ] = 'offline';
                var matching_streamer = $.grep( callback_data[ 'streams' ], function ( streamer_under_search ) {
                    return streamer_under_search[ 'channel' ][ 'name' ] === streamer[ 'name' ];
                } );
                if ( matching_streamer.length > 0 ) {
                    streamer[ 'status' ] = 'online';
                }
            } );

            // Re-organize streamer order based on online status, then by priority.
            streamers.sort( function ( left_obj, right_obj ) {
                if ( left_obj[ 'status' ] === 'online' && right_obj[ 'status' ] === 'offline' ) {
                    return - 1;
                } else if ( left_obj[ 'status' ] === 'offline' && right_obj[ 'status' ] === 'online' ) {
                    return 1;
                } else {
                    return left_obj[ 'priority' ] < right_obj[ 'priority' ] ? - 1 : 1;
                }
            } );

            var streams_changed = false;
            // If main streamer is still online, ONLY re-organize on-deck streams.
            if ( $( 'iframe#main-stream-player' )[ 0 ].src !== get_player_url( streamers[ 0 ][ 'name' ], false ) ) {
                document.getElementById( 'main-stream-player' ).src = get_player_url( streamers[ 0 ][ 'name' ], false );
                document.getElementById( 'chat' ).src = 'https://twitch.tv/' + streamers[ 0 ][ 'name' ] + '/chat?popout=';
                streams_changed = true;
            }

            // Re-organize on-deck streams if they have changed.
            var iframes = $( '.on-deck-stream' );
            $.each( streamers.slice( 1 ), function ( position, streamer ) {
                if ( iframes[ position ].src !== get_player_url( streamer[ 'name' ], true ) ) {
                    iframes[ position ].src = get_player_url( streamer[ 'name' ], true );
                    streams_changed = true;
                }
            } );

            // Finally, reset the list of "switch to" buttons to match the current stream order and status.
            if ( streams_changed ) {
                $.each( $( '.stream-button' ), function ( position, button ) {
                    button.text = streamers[ position ][ 'name' ];
                    button.href = 'http://' + location.host + '/replace_main_stream?streamer=' + streamers[ position ][ 'name' ];
                    if ( streamers[ position ][ 'status' ] === 'offline' ) {
                        $( button ).addClass( 'button-inactive' );
                        $( button ).removeClass( 'button' );
                        $( button ).removeClass( 'button-active' );
                    } else {
                        if ( position === 0 && streamers[ position ][ 'status' ] === 'online' ) {
                            $( button ).removeClass( 'button-inactive' );
                            $( button ).removeClass( 'button' );
                            $( button ).addClass( 'button-active' )
                        } else {
                            $( button ).removeClass( 'button-inactive' );
                            $( button ).removeClass( 'button-active' );
                            $( button ).addClass( 'button' );
                        }
                    }
                } );
            }
        };

        /*
         * Returns a Twitch player URL, filling in the given values of the streamer name and muted flag.
         */
        var get_player_url = function ( name, muted ) {
            return 'http://player.twitch.tv/?channel=' + name + '&auto_play=true&muted=' + muted;
        }

        // Update all streams' status.
        var streamer_names = $.map( streamers, function ( streamer, _ ) {
            return streamer[ 'name' ];
        } ).join( ',' );

        $.ajax( {
            url: 'https://api.twitch.tv/kraken/streams?channel=' + streamer_names,
            async: false
        } ).success( function ( data ) {
            callback_function( data )
        } );
    };

    // Set up an interval to update stream layouts on the page every 15 seconds.
    setInterval( function () {
        // Check if main stream is online
        get_stream_status();
    }, 15000 );
}