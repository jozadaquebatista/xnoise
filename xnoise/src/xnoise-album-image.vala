/* xnoise-album-image.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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

public class Xnoise.AlbumImage : Gtk.Image {
	private const int SIZE = 48;
	private AlbumImageLoader loader = null;
	private Main xn;
	private string artist = "";
	private string album = "";
	private static uint timeout = 0;
	private string default_size = "medium";

	public AlbumImage() {
		xn = Main.instance;
		this.set_size_request(SIZE, SIZE);
		this.set_from_stock(Gtk.STOCK_CDROM, Gtk.IconSize.LARGE_TOOLBAR);

		loader = new AlbumImageLoader();
		loader.sign_fetched.connect(on_album_image_fetched);
		global.uri_changed.connect(on_uri_changed);
	}

	private void on_uri_changed(string? uri) {
		global.check_image_for_current_track();
		if(global.image_path_small == null) {
			string current_uri = uri;
		
			File f = get_file_for_current_artistalbum(global.current_artist, global.current_album, "medium");
			if(f.query_exists(null)) {
				global.check_image_for_current_track();
				set_image_via_idle(f.get_path());
				return;
			}
		
			load_default_image();
			global.check_image_for_current_track();
			if(timeout != 0)
				Source.remove(timeout);
			timeout = Timeout.add_seconds_full(GLib.Priority.DEFAULT,
				                                1,
				                                () => {
				                                	search_image(uri);
				                                	return false;
				                                });
		}
		else {
			File f = File.new_for_path(global.image_path_small);
			if(!f.query_exists(null)) {
				load_default_image();
			}
			else {
				set_image_via_idle(global.image_path_small);
			}
		}
	}

	// Startes via timeout because gPl is sending the tag_changed signals
	// sometimes very often at the beginning of a track.
	private void search_image(string? uri) {

		if(MainContext.current_source().is_destroyed())
			return;
		
		if(uri == null)
			return;
		string _artist = "";
		string _album = "";
		string _artist_raw = "";
		string _album_raw = "";
		
		if((global.current_artist != "unknown artist") && (global.current_album != "unknown album")) {
			_artist_raw = global.current_artist;
			_album_raw  = global.current_album;
			_artist = escape_for_local_folder_search(_artist_raw);
			_album  = escape_for_local_folder_search(_album_raw );
		}
		else {
			return;
		}
		
		if(set_local_image_if_available(ref _artist_raw, ref _album_raw)) 
			return;

		artist = remove_linebreaks(global.current_artist);
		album  = remove_linebreaks(global.current_album );


		var job = new Worker.Job(1, Worker.ExecutionType.ONE_SHOT, null, this.fetch_trackdata_job);
		job.set_arg("artist", artist);
		job.set_arg("album", album);
		job.set_arg("uri", xn.gPl.Uri);
		worker.push_job(job);
	}
	
	
	private void fetch_trackdata_job(Worker.Job job) {
		string artist = (string)job.get_arg("artist");
		string album  = (string)job.get_arg("album");
		string uri    = (string)job.get_arg("uri");
		
		if((artist=="")||(artist==null)||(artist=="unknown artist")||
		   (album =="")||(album ==null)||(album =="unknown album" )) {
			return;
		}

		var image_path = GLib.Path.build_filename(global.settings_folder,
		                                          "album_images",
		                                          null
		                                          );

		var fileout = File.new_for_path(GLib.Path.build_filename(
		                                          image_path,
		                                          escape_for_local_folder_search(artist.down()),
		                                          escape_for_local_folder_search(album.down()),
		                                          escape_for_local_folder_search(album.down()) + 
		                                          "_" + 
		                                          default_size,
		                                          null)
		                                );

		
		if(fileout.query_exists(null)) {
			set_image_via_idle(fileout.get_path());
		}
		else {
			Idle.add( () => {
				loader.artist = artist;
				loader.album  = album;
				loader.fetch_image();
				return false;
			});
		}
		return;
	}

	private bool set_local_image_if_available(ref string _artist, ref string _album) {
		var image_path = GLib.Path.build_filename(global.settings_folder,
		                                          "album_images",
		                                          null
		                                          );

		var fileout = File.new_for_path(GLib.Path.build_filename(
		                                          image_path,
		                                          escape_for_local_folder_search(_artist.down()),
		                                          escape_for_local_folder_search(_album.down()),
		                                          escape_for_local_folder_search(_album.down()) + "_" + default_size,
		                                          null)
		                                );
		//print("xyz local: %s\n", fileout.get_path());
		if(fileout.query_exists(null)) {
			//print("ai exists\n");
			set_image_via_idle(fileout.get_path());
			//update_image_path_in_db(ref _artist, ref _album, fileout.get_path());
			return true;
		}
		return false;
	}
	public void load_default_image() {
		if(source!=0)
			GLib.Source.remove(source);
			
		this.set_size_request(SIZE, SIZE);
		this.set_from_stock(Gtk.STOCK_CDROM, Gtk.IconSize.LARGE_TOOLBAR);
	}

	private void set_albumimage_from_path(string image_path) {
		if(MainContext.current_source().is_destroyed()) 
			return;
		this.set_from_file(image_path);
		Gdk.Pixbuf temp = this.get_pixbuf().scale_simple(SIZE, SIZE, Gdk.InterpType.BILINEAR);
		this.set_from_pixbuf(temp);
	}

	private uint source = 0;
	
	private void on_album_image_fetched(string _artist, string _album, string image_path) {
		//print("called on_image_fetched %s - %s : %s", _artist, _album, image_path);
		if(image_path == "") 
			return;
		
		if((prepare_for_comparison(artist) != prepare_for_comparison(_artist))||
		   (prepare_for_comparison(album)  != prepare_for_comparison(_album ))) 
			return;
		
		File f = File.new_for_path(image_path);
		if(!f.query_exists(null)) 
			return;
		
		set_image_via_idle(image_path);

		Idle.add( () => {
			global.check_image_for_current_track();
			return false;
		});
	}
	
	private void set_image_via_idle(string image_path) {
		if(image_path == "")
			return;
		
		if(source != 0)
			Source.remove(source);
			
		source = Idle.add( () => {
			this.set_albumimage_from_path(image_path);
			return false;
		});
	}
}
