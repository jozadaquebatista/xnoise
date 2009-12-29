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

public class Xnoise.LastFmCoversPlugin : GLib.Object, IPlugin, IAlbumCoverImageProvider {
	public Main xn { get; set; }
	public string name { 
		get {
			return "lastFmCovers";
		} 
	}

	public bool init() {
		return true;
	}

	public Gtk.Widget? get_settings_widget() {
		// TODO: Here we maybe need a Widget to put the user/pswd,
		// key or account date for lastfm
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	public Xnoise.IAlbumCoverImage from_tags(string artist, string album) {
		return new LastFmCovers(artist, album);
	} 
}



public class Xnoise.LastFmCovers : GLib.Object, IAlbumCoverImage {
	private const string INIFOLDER = ".xnoise";
	//private static SessionAsync session;
	private static SessionSync session;
	static string lastfmKey = "b25b959554ed76058ac220b7b2e0a026";
	
	private string artist;
	private string album;
	private string image_uri = "";

	public LastFmCovers(string artist, string album) {
		this.artist = artist;
		this.album = album;
		print("new backend\n");
	}
	
	~LastFmCovers() {
		print("dstrct backend\n");
	}

	public void* fetch_image() {
		string s = find_image(this.artist, this.album);
		sign_album_image_fetched(s);
		sign_album_image_done(this);
		return null;
	}

	private string? download_album_images(string artist,string album,XPathContext* xpath) {
		string[] sizes = {"medium", "extralarge"}; //Two sizes seem to be enough for now
		string default_size = "medium";
		string uri_image = "";
		var image_path = GLib.Path.build_filename(GLib.Environment.get_home_dir(),
		                                          INIFOLDER,
		                                          "album_images",
		                                          null
		                                          );

		for( int i = 0; i< sizes.length;i++) {
			var fileout = File.new_for_path(GLib.Path.build_filename(
			                                          image_path,
			                                          escape_for_local_folder_search(artist.down()),
			                                          escape_for_local_folder_search(album.down()),
			                                          escape_for_local_folder_search(album.down()) +
			                                          "_" +
			                                          sizes[i],
			                                          null)
			                                );
/*		var image_path = GLib.Path.build_filename(GLib.Environment.get_home_dir(),
		                                          INIFOLDER,
		                                          "album_images",
		                                          null
		                                          );

			var fileout = File.new_for_path(GLib.Path.build_filename(
			                                          image_path,
			                                          artist.down(),
			                                          album.down(),
			                                          album.down() + "_" + sizes[i],
			                                          null)
			                                );
*/
			if(default_size == sizes[i]) uri_image = fileout.get_path();     

			string pth = "";
			File fileout_path = fileout.get_parent();
			if(!fileout_path.query_exists(null)) {
				try {
					fileout_path.make_directory_with_parents(null);
				}
				catch(GLib.Error e) {
					print("Error with create image directory: %s\npath: %s", e.message, pth);
					return null;
				}
			}

			if(!fileout.query_exists (null)) {
				XPathObject* result = xpath->eval_expression("/lfm/album/image[@size='" + sizes[i] +"']");
				if(result->nodesetval->is_empty() ) {
					continue; //Remote file not exist
				}
				else {
					string url_image = result->nodesetval->item(0)->get_content();
					var remote_file = File.new_for_uri(url_image);
					if(remote_file.query_exists(null)) { //remote file exist
						try {
							//print("Begin download file %s\n",remote_file.get_basename() );
							remote_file.copy(fileout, FileCopyFlags.NONE, null, null);
							//print("Finish download file %s\n", fileout.get_path());
						}
						catch(GLib.Error e) {
							print("%s\n", e.message);
						}
					}
					else {
						continue;
					}
				}
			}
			else {
				continue; //Local file exists
			}
		}

		if(uri_image == "") {
			return null;
		}
		else {
			return uri_image;
		}
	}

	private string? find_image(string artist, string album) {
		//print("find_lastfm_image to %s - %s\n", artist, album);
		session = new Soup.SessionSync();
		string url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=" + lastfmKey + "&artist=" + 			artist +"&album=" + album;
		//print(url+"\n");
		var message = new Soup.Message("GET", url);
		session.send_message(message);
		Xml.Doc* doc = Parser.parse_memory(message.response_body.data,(int)message.response_body.length);
		XPathContext* xpath = new XPathContext(doc);

		XPathObject* result = xpath->eval_expression("/lfm/@status");
		if( result->nodesetval->is_empty() ) {
			return null;
		}
		else {
			string state = result->nodesetval->item(0)->get_content();
			if(state == "ok") {
				return download_album_images(artist, album, xpath);
			}
			else {
				return null;
			}
		}
	}
	
	private string get_image_uri() {
		return image_uri;
	}
}
