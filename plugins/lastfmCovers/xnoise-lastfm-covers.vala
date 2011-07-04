/* xnoise-lastfm-covers.vala
 *
 * Copyright (C) 2009 - 2010 Jörn Magens
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

using Gtk;
using Soup;
using Xml;
using Xnoise;
using Xnoise.Services;

// Plugin for lastfm.com PHP API

public class Xnoise.LastFmCoversPlugin : GLib.Object, IPlugin, IAlbumCoverImageProvider {
	private unowned Xnoise.Plugin _owner;
	
	public Main xn { get; set; }
	
	public Xnoise.Plugin owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}
	public string name {
		get {
			return "lastFmCovers";
		}
	}

	public bool init() {
		return true;
	}

	public void uninit() {
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



/**
 * The LastFmCovers class tries to find cover images on 
 * lastFm.
 * The images are downloaded to a local folder below ~/.xnoise
 * The download folder is returned via a signal together with
 * the artist name and the album name for identification.
 * 
 * This class should be called from a closure to work with full
 * mainloop integration. No threads needed!
 * Copying is also done asynchonously.
 */
public class Xnoise.LastFmCovers : GLib.Object, IAlbumCoverImage {
	private const int SECONDS_FOR_TIMEOUT = 12;
	// Maybe add this key as a construct only property. Then it can be an individual key for each user
	private const string lastfmKey = "b25b959554ed76058ac220b7b2e0a026";
	
	private const string INIFOLDER = ".xnoise";
	private SessionAsync session;
	private string artist;
	private string album;
	private File f = null;
	private string image_path;
	private string[] sizes;
	private File[] image_sources;
	private uint timeout;
	private bool timeout_done;
	
	public LastFmCovers(string _artist, string _album) {
		this.artist = _artist;
		this.album  = _album;
		image_path = GLib.Path.build_filename(global.settings_folder,
		                                      "album_images",
		                                      null
		                                      );
		image_sources = {};
		sizes = {"medium", "extralarge"}; //Two are enough
		timeout = 0;
		timeout_done = false;
	}
	
	~LastFmCovers() {
		if(timeout != 0)
			Source.remove(timeout);
	}

	private void remove_timeout() {
		if(timeout != 0)
			Source.remove(timeout);
	}
	
	public void find_image() {
		//print("find_lastfm_image to %s - %s\n", artist, album);
		if((artist=="unknown artist")||
		   (album=="unknown album")) {
			sign_image_fetched(artist, album, "");
			this.unref();
			return;
		}
			
		session = new Soup.SessionAsync();
		string url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=" + 
		             lastfmKey + 
		             "&artist=" + 
		             replace_underline_with_blank_encoded(Soup.URI.encode(artist, null)) +
		             "&album=" + 
		             replace_underline_with_blank_encoded(Soup.URI.encode(album , null));
		var message = new Soup.Message("GET", url);
		session.queue_message(message, soup_cb);
		
		//Add timeout for response
		timeout = Timeout.add_seconds(SECONDS_FOR_TIMEOUT, timeout_elapsed);
	}
	
	private bool timeout_elapsed() {
		this.timeout_done = true;
		this.unref();
		return false;
	}
	
	private void soup_cb(Session sess, Message mess) {
		if(mess == null || mess.response_body == null || mess.response_body.data == null) {
			//print("empty message\n");
			sign_image_fetched(artist, album, "");
			// unrefing is maybe not needed as the timeout should do it
			return;
		}
		
		//print("mess.response_body.data: %s\n", mess.response_body.data);
		Xml.Doc* doc = Parser.parse_memory((string)mess.response_body.flatten().data,(int)mess.response_body.length);
		
		XPath.Context* xpath = new XPath.Context(doc);
		XPath.Object* result = xpath->eval_expression("/lfm/@status");
		if(result->nodesetval->is_empty()) {
			//print("node is empty\n");
		}
		else {
			string state = result->nodesetval->item(0)->get_content();
			if(state == "ok") {
				string default_size = "medium";
				string uri_image = "";

				foreach(string s in sizes) {
					f = get_albumimage_for_artistalbum(artist, album, s);
					if(default_size == s) uri_image = f.get_path();

					string pth = "";
					File f_path = f.get_parent();
					if(!f_path.query_exists(null)) {
						try {
							f_path.make_directory_with_parents(null);
						}
						catch(GLib.Error e) {
							print("Error with create image directory: %s\npath: %s", e.message, pth);
							delete xpath;
							delete doc;
							remove_timeout();
							this.unref();
							return;
						}
					}

					if(!f.query_exists(null)) {
						result = xpath->eval_expression("/lfm/album/image[@size='" + s +"']"); //XPathObject* 
						if(result->nodesetval->is_empty() ) {
							continue; //Remote file not exist or no network connection
						}
						else {
							string url_image = result->nodesetval->item(0)->get_content();
							var remote_file = File.new_for_uri(url_image);
							image_sources += remote_file;
						}
					}
					else {
						//print("Local file already exists\n");
						continue; //Local file exists
					}
				}
				string reply_artist = "";
				result = xpath->eval_expression("/lfm/album/artist");
				if(result->nodesetval->is_empty()) {
					reply_artist = "";
				}
				else {
					reply_artist = result->nodesetval->item(0)->get_content();
				}
				string reply_album = "";
				result = xpath->eval_expression("/lfm/album/name");
				if(result->nodesetval->is_empty()) {
					reply_album = "";
				}
				else {
					reply_album = result->nodesetval->item(0)->get_content();
				}
				//use the reply's artist/album to make sure the right combination is used'
				this.copy_covers_async(reply_artist.down(), reply_album.down());
			}
		}
		delete xpath;
		delete doc;
		return;
	}

	private async void copy_covers_async(string _reply_artist, string _reply_album) {
		File destination;
		bool buf = false;
		string default_path = "";
		int i = 0;
		string reply_artist = _reply_artist;
		string reply_album = _reply_album;
		
		foreach(File f in image_sources) {
			var s = sizes[i];
			destination = get_albumimage_for_artistalbum(reply_artist, reply_album, s);
			try {
				if(f.query_exists(null)) { //remote file exist
					
					buf = yield f.copy_async(destination,
					                         FileCopyFlags.OVERWRITE,
					                         Priority.DEFAULT,
					                         null,
					                         null);
				}
				else {
					continue;
				}
				if(sizes[i] == "medium") default_path = destination.get_path();
				i++;
			}
			catch(GLib.Error e) {
				print("Error: %s\n", e.message);
				i++;
				continue;
			}
		}
		// signal finish with artist, album in order to identify the sent image
		sign_image_fetched(reply_artist, reply_album, default_path);

		remove_timeout();
		
		if(!this.timeout_done) {
			this.unref(); // After this point LastFmCovers downloader can safely be removed
		}
		return;
	}
}

