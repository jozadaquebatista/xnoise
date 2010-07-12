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
		UNHANDLED = 0, //The playlist could not be handled.
		ERROR,         //There was an error parsing the playlist.
		IGNORED,       //The playlist was ignored due to its scheme 
		SUCCESS        //The playlist was parsed successfully.
	}
	
	//put some debug messages into the code
	public bool debug = false;
}

