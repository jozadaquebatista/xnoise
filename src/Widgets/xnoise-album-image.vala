/* xnoise-album-image.vala
 *
 * Copyright (C) 2009-2011  Jörn Magens
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
		this.set_from_icon_name("xnoise-panel", Gtk.IconSize.DIALOG);
		
		loader = new AlbumImageLoader();
		loader.sign_fetched.connect(on_album_image_fetched);
		global.uri_changed.connect(on_uri_changed);
		global.sign_image_path_large_changed.connect( () => {
			set_image_via_idle(global.image_path_large);
		});
	}

	private void on_uri_changed(string? uri) {
		string current_uri = uri;
		Timeout.add(200, () => {
			global.check_image_for_current_track();
			if(global.image_path_small == null) {
				File f = get_albumimage_for_artistalbum(global.current_artist, global.current_album, "medium");
				if(f != null && f.query_exists(null)) {
					return false;
				}
				string current_uri1 = current_uri;
				load_default_image();
				if(timeout != 0) {
					Source.remove(timeout);
					timeout = 0;
				}
				timeout = Timeout.add_seconds(1, () => {
					search_image(current_uri1);
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
			return false;
		});
	}

	// Startes via timeout because gPl is sending the tag_changed signals
	// sometimes very often at the beginning of a track.
	private void search_image(string? uri) {
		if(MainContext.current_source().is_destroyed())
			return;
		
		if(uri == null || uri == "")
			return;
		string _artist = "";
		string _album = "";
		string _artist_raw = "";
		string _album_raw = "";
		
		if((global.current_artist != null && global.current_artist != "unknown artist") && 
		   (global.current_album != null && global.current_album != "unknown album")) {
			_artist_raw = global.current_artist;
			_album_raw  = global.current_album;
			_artist = escape_for_local_folder_search(_artist_raw);
			_album  = escape_album_for_local_folder_search(_artist, _album_raw );
		}
		else {
			File? thumb = null;
			if(thumbnail_available(global.current_uri, out thumb)) {
				set_image_via_idle(thumb.get_path());
			}
			return;
		}
		
		if(set_local_image_if_available(ref _artist_raw, ref _album_raw)) 
			return;
		
		artist = remove_linebreaks(global.current_artist);
		album  = remove_linebreaks(global.current_album );
		
		
		var job = new Worker.Job(Worker.ExecutionType.ONCE, this.fetch_trackdata_job);
		job.set_arg("artist", artist);
		job.set_arg("album", album);
		job.set_arg("uri", xn.gPl.uri);
		db_worker.push_job(job);
	}
	
	
	private bool fetch_trackdata_job(Worker.Job job) {
		string jartist = (string)job.get_arg("artist");
		string jalbum  = (string)job.get_arg("album");
		//string uri    = (string)job.get_arg("uri");
		
		if((jartist=="")||(jartist==null)||(jartist=="unknown artist")||
		   (jalbum =="")||(jalbum ==null)||(jalbum =="unknown album" )) {
			return false;
		}
		var fileout = get_albumimage_for_artistalbum(jartist, jalbum, default_size);
		
		if(fileout.query_exists(null)) {
			global.check_image_for_current_track();
		}
		else {
			Idle.add( () => {
				loader.artist = jartist;
				loader.album  = check_album_name(jartist, jalbum);
				loader.fetch_image();
				return false;
			});
		}
		return false;
	}

	private bool set_local_image_if_available(ref string _artist, ref string _album) {
		var fileout = get_albumimage_for_artistalbum(_artist, _album, default_size);
		if(fileout.query_exists(null)) {
			set_image_via_idle(fileout.get_path());
			return true;
		}
		return false;
	}
	
	public void load_default_image() {
		this.set_size_request(SIZE, SIZE);
		this.set_from_icon_name("xnoise-panel", Gtk.IconSize.DIALOG);
	}

	private void set_albumimage_from_path(string? image_path) {
		if(MainContext.current_source().is_destroyed())
			return;
		
		if(image_path == null) {
			load_default_image();
			return;
		}
		File f = File.new_for_path(image_path);
		if(!f.query_exists(null)) {
			load_default_image();
			return;
		}
		this.set_from_file(image_path);
		Gdk.Pixbuf temp = this.get_pixbuf().scale_simple(SIZE, SIZE, Gdk.InterpType.BILINEAR);
		this.set_from_pixbuf(temp);
	}

	private uint source = 0;
	
	private void on_album_image_fetched(string _artist, string _album, string image_path) {
		//print("\ncalled on_image_fetched %s - %s : %s", _artist, _album, image_path);
		if(image_path == "") 
			return;
		
		if((prepare_for_comparison(artist) != prepare_for_comparison(_artist))||
		   (prepare_for_comparison(check_album_name(artist, album))  != prepare_for_comparison(check_album_name(_artist, _album)))) 
			return;
		//print("  ..  comply\n");
		File f = File.new_for_path(image_path);
		if(!f.query_exists(null)) 
			return;
		
		global.check_image_for_current_track();
		set_image_via_idle(image_path);
	}
	
	private void set_image_via_idle(string? image_path) {
		if(image_path == null || image_path == "")
			return;
		
		if(source != 0) {
			Source.remove(source);
			source = 0;
		}
			
		source = Timeout.add_seconds(2, () => {
			this.set_albumimage_from_path(image_path);
			return false;
		});
	}
}
