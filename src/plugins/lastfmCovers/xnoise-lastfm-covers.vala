/* xnoise-lastfm-covers.vala
 *
 * Copyright (C) 2009 Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 * softshaker
 * Jörn Magens
 * fsistemas
 */
 //TODO: only call this if local file is not available
 // Do everything async
using Gtk;
using Soup;
using Xml;

// Plugin for lastfm.com PHP API

public class LastFmCoversPlugin : GLib.Object, Xnoise.IPlugin, Xnoise.IAlbumCoverImageProvider {
	public Xnoise.Main xn { get; set; }
	public string name { 
		get {
			return "lastFmCovers";
		} 
	}
    //TODO: Is this needed?
	public bool init() {
		return true;
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	public Xnoise.IAlbumCoverImage from_tags(string artist, string album) {
		return new LastFmCovers(artist, album);
	} 
}



public class LastFmCovers : GLib.Object, Xnoise.IAlbumCoverImage {
	private const string INIFOLDER = ".xnoise";
	private static SessionAsync session;
	static string lastfmKey = "b25b959554ed76058ac220b7b2e0a026";
	
	private string artist;
	private string album;
	private string image_uri = "";
	//private bool? availability;
		
	public LastFmCovers(string artist, string album) {
		this.artist = artist;
		this.album = album;
	}
	
	private string? find_image(string artist, string album) {
		print("find_lastfm_image to %s - %s\n", artist, album);
		session = new Soup.SessionAsync();
		string url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=" + lastfmKey + "&artist=" + 			artist +"&album=" + album;
		print(url+"\n");
		var message = new Soup.Message("GET", url);
		session.send_message(message);
		Xml.Doc* doc = Parser.parse_memory(message.response_body.data,(int)message.response_body.length);
		XPathContext* xpath = new XPathContext(doc);
		XPathObject* result = xpath->eval_expression("/lfm/album/image[@size='extralarge']");

		if( result->nodesetval->is_empty() ) {
			//load_default_image();
			return null;
		}
		string url_image = result->nodesetval->item(0)->get_content();
		var file = File.new_for_uri(url_image);
		if(file.query_exists(null)) { //If remote file does not exist
			var image_path = GLib.Path.build_filename(GLib.Environment.get_home_dir(), INIFOLDER, "album_images", null);
			var fileout = File.new_for_path(GLib.Path.build_filename(image_path, artist.down(), album.down(), file.get_basename(), null));
			string pth = "";
			File fileout_path = fileout.get_parent();
			if(!fileout_path.query_exists(null)) {
				try {
					fileout_path.make_directory_with_parents(null);
				} 
				catch(GLib.Error e) {
					stderr.printf("Error with create image directory: %s\npath: %s", e.message, pth);
					return null;
				}
			}




			if(!fileout.query_exists(null)) { //If local image file does not exist.
				try {
					print("Download file %s\n", fileout.get_path());
					file.copy(fileout, FileCopyFlags.NONE, null, null);
				}
				catch(GLib.Error e) {
					print("%s\n", e.message);
					return null;
				}
			}
			else { //El archivo local existe
				print("Local image %s exists.\n",file.get_basename () );
			}
//			set_albumimage_from_uri(fileout.get_path());
			return fileout.get_path();
		}
		else {
//			load_default_image();
			print ("The remote image %s does not exist\n", file.get_basename());
			return null;
		}
	}
	
//	public bool? available() {
//		return availability;
//	}
	
	public void fetch () {
		string s = find_image(this.artist, this.album);
//		if(available() == null) {
//			//find_lastfm_image();
//			print("not available\n");
//			return null;
//		}
//		if(!available()){
//			sign_aimage_done(this);
//			return null;
//		}
////		fetch_text();
		sign_aimage_fetched(s);
		sign_aimage_done(this);
		return;
	}
	
	public string get_image_uri() {
		return image_uri;
	}
}
