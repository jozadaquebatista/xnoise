/* xnoise-misc.vala
 *
 * Copyright (C) 2009  Jörn Magens
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * Jörn Magens
 */

public enum Xnoise.MusicBrModColumn { //TODO: Rename
	ICON = 0,
	VIS_TEXT,
	ARTIST_ID,
	ALBUM_ID,
	TITLE_ID
}

public struct Xnoise.TrackData {
	public string Artist;
	public string Album;
	public string Title;
	public string Genre;
	public uint Tracknumber;
}

public enum Xnoise.TrackListColumn {
	STATE = 0,
	ICON,
	TRACKNUMBER,
	TITLE,
	ALBUM,
	ARTIST,
	URI
}

public enum Xnoise.TrackStatus { //TODO: Rename
	STOPPED = 0,
	PLAYING,
	PAUSED,
	POSITION_FLAG
}

public enum Xnoise.Direction {
	NEXT = 0,
	PREVIOUS,
}

public enum Xnoise.TagReaderField {
	ARTIST = 0,
	TITLE,
	ALBUM,
	GENRE,
	TRACKNUMBER
}

public interface Xnoise.IParameter : GLib.Object {
		public abstract void read_data(KeyFile file) throws KeyFileError;
		public abstract void write_data(KeyFile file);
}



