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
		NO_DATA,
		NO_DEST_URI,
		DEST_REMOTE
	}
	
	private errordomain InternalReaderError {
		UNKNOWN_TYPE,
		INVALID_FILE,
		SOMETHING_ELSE
	}

	private errordomain InternalWriterError {
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
		EMPTY,         //Reding returned no data
		DOUBLE_WRITE   //There was already a write in progress for current writer instance
	}
	
	public enum TargetType {
		URI,           // a uri is a uri
		REL_PATH,      // path relative to the location of the playlist
		ABS_PATH       // absolute path (local only !)
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
	
	public const string[] remote_schemes = { "http", "ftp" }; // TODO: add more
}

