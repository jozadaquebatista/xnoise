/* xnoise-album-image.vala
 *
 * Copyright (C) 2009  Jörn Magens
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
 * 	Jörn Magens
 * 	softshaker  softshaker googlemail.com
 * 	fsistemas
 */

using Gtk;

public class Xnoise.AlbumImage : Gtk.Fixed {
	// TODO: Local search is not working yet.
	public Gtk.Image albumimage;
	private const string INIFOLDER = ".xnoise";
	private AlbumImageLoader loader = null;
	private Main xn;
	private string artist = "";
	private string album = "";
	private static uint timeout = 0;
	private string default_size = "medium";
	private bool db_image_available = false;

	public bool album_image_available { get; private set; default = false; }
	public string current_image_path  { get; private set; default = ""; }

//	public signal void sign_cov_image_available();

	public AlbumImage() {
		xn = Main.instance();
		AlbumImageLoader.init();
		albumimage = new Gtk.Image();
		albumimage.set_size_request(48, 48);
		albumimage.set_from_stock(Gtk.STOCK_CDROM, Gtk.IconSize.LARGE_TOOLBAR);
		this.put(albumimage, 0, 0);
		xn.gPl.sign_uri_changed.connect(on_uri_changed);
		xn.gPl.sign_tag_changed.connect(on_tag_changed);
//		this.notify.connect( (s, p) => {
//			switch(p.name) {
//				case "album-image-available": {
//					sign_cov_image_available();
//					break;
//				}
//				default: break;
//			}
//		});
	}

	private void on_tag_changed(string uri) {
		if(timeout!=0)
			GLib.Source.remove(timeout);

		timeout = GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT,
		                                        2,
		                                        on_timout_elapsed);
	}

	private void on_uri_changed(string uri) {
		album_image_available = false;
		current_image_path = "";
		db_image_available = false;
		string current_uri = uri;
		var dbb = new DbBrowser();
		string? res = dbb.get_local_image_path_for_uri(ref current_uri);
		dbb = null;
		if((res!=null)&&(res!="")) {
			//print("db has image entry\n");
			File f = File.new_for_path(res);
			if(!f.query_exists(null)) {
				load_default_image();
				return;
			}
			db_image_available = true;
			current_image_path = res;
			if(source!=0)
				GLib.Source.remove(source);
			source = Idle.add(this.set_albumimage_from_path);
			album_image_available = true;
		}
		else {
			//print("has no image entry\n");
			load_default_image();
		}
	}

	// Use the timeout because gPl is sending the sign_tag_changed signals
	// sometimes very often at the beginning of a track.
	private bool on_timout_elapsed() {
		if(db_image_available) return false;
		if(loader != null)
			loader.sign_fetched.disconnect(on_album_image_fetched);

		artist = escape_for_local_folder_search(xn.gPl.currentartist);
		album  = escape_for_local_folder_search(xn.gPl.currentalbum );
		//print("1. %s - %s\n", artist, album);
		if(set_local_image_if_available(artist, album)) return false;

		artist = remove_linebreaks(xn.gPl.currentartist);
		album  = remove_linebreaks(xn.gPl.currentalbum );

		// Look into db in case gPl does not provide the tag
		if((artist=="unknown artist")||(album =="unknown album" )) {
			var dbb = new DbBrowser();
			TrackData td;
			if(dbb.get_trackdata_for_uri(xn.gPl.Uri, out td)) {
				artist = td.Artist;
				album = td.Album;
			}
		}

		//print("2. %s - %s\n", artist, album);
		if((artist=="")||(artist==null)||(artist=="unknown artist")||
		   (album =="")||(album ==null)||(album =="unknown album" )) {
			return false;
		}

		var image_path = GLib.Path.build_filename(GLib.Environment.get_home_dir(),
		                                          INIFOLDER,
		                                          "album_images",
		                                          null
		                                          );

		var fileout = File.new_for_path(GLib.Path.build_filename(
		                                          image_path,
		                                          escape_for_local_folder_search(artist.down()),
		                                          escape_for_local_folder_search(album.down()),
		                                          escape_for_local_folder_search(album.down()) + "_" + default_size,
		                                          null)
		                                );

		if(fileout.query_exists(null)) {
			//print("using local path for album image: %s", fileout.get_path());
			current_image_path = fileout.get_path();
			if(source!=0)
				GLib.Source.remove(source);
			source = Idle.add(this.set_albumimage_from_path);
			album_image_available = true;
			current_image_path = fileout.get_path();
		}
		else {
			if(loader != null) {
				loader.sign_fetched.disconnect(on_album_image_fetched);
			}
			loader = new AlbumImageLoader(artist, album);
			loader.sign_fetched.connect(on_album_image_fetched);
			loader.fetch_image();
		}
		return false;
	}

	private bool set_local_image_if_available(string artist, string album) {
		var image_path = GLib.Path.build_filename(GLib.Environment.get_home_dir(),
		                                          INIFOLDER,
		                                          "album_images",
		                                          null
		                                          );

		var fileout = File.new_for_path(GLib.Path.build_filename(
		                                          image_path,
		                                          escape_for_local_folder_search(artist.down()),
		                                          escape_for_local_folder_search(album.down()),
		                                          escape_for_local_folder_search(album.down()) + "_" + default_size,
		                                          null)
		                                );
		//print("xyz local: %s\n", fileout.get_path());
		if(fileout.query_exists(null)) {
			//print("using local path for album image: %s\n", fileout.get_path());
			current_image_path = fileout.get_path();
			if(source!=0)
				GLib.Source.remove(source);
			source = Idle.add(this.set_albumimage_from_path);
			album_image_available = true;
			current_image_path = fileout.get_path();
			return true;
		}
		return false;
	}

	public void load_default_image() {
		if(source!=0)
			GLib.Source.remove(source);
		current_image_path = "";
		album_image_available = false;
		this.albumimage.set_size_request(48, 48);
		this.albumimage.set_from_stock(Gtk.STOCK_CDROM, Gtk.IconSize.LARGE_TOOLBAR);
	}

	private bool set_albumimage_from_path() {
		this.albumimage.set_from_file(current_image_path);
		return false;
	}

	private static uint source = 0;

	private void on_album_image_fetched(string? image_path) {
		//print("image ready: %s\n", image_path);
		if((image_path == null)||(image_path == "")) return;

		File f = File.new_for_path(image_path);
		if(!f.query_exists(null)) return;

		current_image_path = image_path;
		if(source!=0)
			GLib.Source.remove(source);
		source = Idle.add(this.set_albumimage_from_path);
		current_image_path = image_path;
		album_image_available = true;
		var dbw = new DbWriter();
		dbw.set_local_image_for_album(ref artist, ref album, image_path);
		dbw = null;
	}
}
