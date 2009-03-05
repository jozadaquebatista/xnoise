using GLib;

public enum Xnoise.TagReaderField {
	ARTIST = 0,
	TITLE,
	ALBUM,
	GENRE
}

//connection to to taglib_c
public class Xnoise.TagReader : GLib.Object {

	public string[] read_tag_from_file(string file) {
		string[] tags; 
		TagLib.File taglib_file = new TagLib.File(file);
		if(taglib_file!=null) {
			weak TagLib.Tag t = taglib_file.tag; 
			tags = new string[4];
			try {
				tags[TagReaderField.ARTIST] = t.artist;
				tags[TagReaderField.TITLE]  = t.title;
				tags[TagReaderField.ALBUM]  = t.album;
				tags[TagReaderField.GENRE]  = t.genre;
			}
			finally {
				if ((tags[TagReaderField.ARTIST] == "")||(tags[TagReaderField.ARTIST] == null)) tags[TagReaderField.ARTIST] = "unknown artist";
				if ((tags[TagReaderField.TITLE]  == "")||(tags[TagReaderField.TITLE]  == null)) tags[TagReaderField.TITLE]  = "unknown title";
				if ((tags[TagReaderField.ALBUM]  == "")||(tags[TagReaderField.ALBUM]  == null)) tags[TagReaderField.ALBUM]  = "unknown album";
				if ((tags[TagReaderField.GENRE]  == "")||(tags[TagReaderField.GENRE]  == null)) tags[TagReaderField.GENRE]  = "unknown genre";
				t = null;
				taglib_file = null;
			}
			return tags;
		}
		else {
			tags = new string[4];
			int count = 0;
			if ((tags[TagReaderField.ARTIST] == "")||(tags[TagReaderField.ARTIST] == null)) {
				tags[TagReaderField.ARTIST] = "unknown artist";
				count++;
			}
			if ((tags[TagReaderField.TITLE]  == "")||(tags[TagReaderField.TITLE]  == null)) {
				tags[TagReaderField.TITLE]  = "unknown title";
				count++;
			}
			if ((tags[TagReaderField.ALBUM]  == "")||(tags[TagReaderField.ALBUM]  == null)) {
				tags[TagReaderField.ALBUM]  = "unknown album";
				count++;
			}
			if(count==3) {
				tags[TagReaderField.ARTIST] = "";
				tags[TagReaderField.ALBUM]  = "";
				string fileBasename = GLib.Filename.display_basename(file);
				tags[TagReaderField.TITLE]  = fileBasename;
			}
			if ((tags[TagReaderField.GENRE]  == "")||(tags[TagReaderField.GENRE]  == null)) {
				tags[TagReaderField.GENRE]  = "unknown genre";
			}
			return tags;
		}
	}
}

