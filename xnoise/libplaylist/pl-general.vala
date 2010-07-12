/* pl-general.vala
 *
 * Copyright (C) 2010  Jörn Magens
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jörn Magens <shuerhaaken@googlemail.com>
 */


namespace Pl {

	public errordomain ReaderError {
		UNKNOWN_TYPE,
		SOMETHING_ELSE
	}

	public errordomain WriterError {
		UNKNOWN_TYPE,
		SOMETHING_ELSE
	}
	
	private errordomain Internal.ReaderError {
		UNKNOWN_TYPE,
		SOMETHING_ELSE
	}

	private errordomain Internal.WriterError {
		UNKNOWN_TYPE,
		SOMETHING_ELSE
	}
	
	//Type of playlist
	public enum ListType {
		UNKNOWN = 0,
		IGNORED,
		M3U,
		PLS,
		ASX,
		XSPF
	}
	
	public enum Result {
		UNHANDLED = 0, //Playlist could not be handled
		ERROR,         //Error reading playlist
		IGNORED,       //Playlist was ignored for some reason
		SUCCESS,       //Playlist was read successfully
		EMPTY          //Reding returned no data
	}
	
	// string constants for content types
	private static class ContentType {
		public const string ASX         = "audio/x-ms-asx";
		public const string PLS         = "audio/x-scpls";
		public const string APPLE_MPEG  = "application/vnd.apple.mpegurl";
		public const string X_MPEG      = "audio/x-mpegurl";
		public const string MPEG        = "audio/mpegurl";
		public const string XSPF        = "application/xspf+xml";
	}
	
	//put some debug messages into the code
	public bool debug = false;
	
	
	// Static helper functions
	
	// duration in seconds
	public static long get_duration_from_string(ref string? duration_string) {
		
		if(duration_string == null)
			return -1;
		
		long duration = 0;
		int hours = 0; 
		int minutes = 0; 
		int seconds = 0; 
		int fractions_of_seconds = 0;
		
		// Try scanning different formats
		
		if(duration_string.scanf("%d:%d:%d.%d", ref hours, ref minutes, ref seconds, ref fractions_of_seconds) == 4) {
			duration = hours * 3600 + minutes * 60 + seconds;
			return (duration == 0 && fractions_of_seconds > 0) ? 1 : duration;
		}
		
		if(duration_string.scanf("%d:%d.%d", ref minutes, ref seconds, ref fractions_of_seconds) == 3) {
			duration = minutes * 60 + seconds;
			return (duration == 0 && fractions_of_seconds > 0) ? 1 : duration;
		}
		
		if(duration_string.scanf("%d:%d:%d", ref hours, ref minutes, ref seconds) == 3) 
			return hours * 3600 + minutes * 60 + seconds;
		
		if(duration_string.scanf("%d.%d", ref minutes, ref seconds) == 2) 
			return minutes * 60 + seconds;
		
		if(duration_string.scanf("%d:%d", ref minutes, ref seconds) == 2) 
			return minutes * 60 + seconds;
		
		if(duration_string.scanf("%d", ref seconds) == 1) 
			return seconds;
		
		return -1; // string didn't match the scanning formats
	}
}

