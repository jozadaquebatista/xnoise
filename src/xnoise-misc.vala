


public enum Xnoise.MusicBrModColumn { //TODO: Rename
	ICON = 0,
	VIS_TEXT,
	ARTIST_ID,
	ALBUM_ID,
	TITLE_ID
}

public struct Xnoise.trackData {
	public string Artist;
	public string Album;
	public string Title;
}



public enum Xnoise.TrackListColumn {
	STATE = 0,
	ICON,
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



public interface Xnoise.IConfigure : GLib.Object {
		public abstract void read_data(KeyFile file) throws KeyFileError;
		public abstract void write_data(KeyFile file);
}



