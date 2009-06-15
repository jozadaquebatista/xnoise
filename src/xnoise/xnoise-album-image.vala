/* xnoise-main-window.vala
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
 *  Andre Osku Schmitt
 */

using Gtk;

public class Xnoise.AlbumImage : Gtk.Fixed {
	// NOTE! some stream channels send title in ~5min intervals!
	// TODO: get image from tag
	// TODO: get image from folder
	// TODO: get image from service (with api)

	static Gtk.Image albumimage; // this would be that from xnoise
	static Gtk.Image albumimage_overlay; // UI 2.0 hack ;P
	
	static string gooc_img_uri = "";
	static string orig_img_uri = "";
	static string working_animation = Config.UIDIR + "working_animation.gif";
	
	private const string goo_prefix = "http://images.google.com/images?hl=en&q=";
	private const string goo_suffix = "&btnG=Search+Images&gbv=1";

	public AlbumImage() {
		albumimage = new Gtk.Image();
		albumimage.set_size_request(48, 48);
		albumimage_overlay = new Gtk.Image();
		albumimage_overlay.set_size_request(48, 48);
		albumimage.set_from_stock(Gtk.STOCK_CDROM, Gtk.IconSize.LARGE_TOOLBAR);
		this.put(albumimage, 0, 0);
		this.put(albumimage_overlay, 0, 0);
	}

	private uint timeout;
	private string current_uri;
	
	public void find_album_image(string uri) {
		if((uri!=current_uri) ) Source.remove(timeout);
		if(timeout != 0) return;
		timeout = GLib.Timeout.add(1000, on_wait_for_tags);
		current_uri = uri;
	}

	private bool on_wait_for_tags() {
		DbBrowser db = new DbBrowser();
		Xnoise.TrackData td;
		if(db.get_trackdata_for_uri(current_uri, out td)) {
			string abc = td.Artist + " - " + td.Album;
			print("searching image for %s\n", abc);
			find_google_image(abc);
		}
		return false;
	}

	public void find_google_image (string search_term) {
		//TODO: test if adding "cover" (or similar) to term gets better results
		print ("search image for: \"%s\"\n", search_term);
		string goo_search = goo_encode (search_term);
		string goo_uri = goo_prefix + goo_search + goo_suffix;
		print ("goouri: %s\n", goo_uri);
		
		var file = File.new_for_uri (goo_uri);
		
		try {
			string line;
			bool found = false;
			var in_stream = new DataInputStream (file.read (null));

			while ((line = in_stream.read_line (null, null)) != null) {
				if (line.has_prefix("<table") && !found) {
					found = true;

					// google cached image uri
					gooc_img_uri = line.split ("</a></td>", 2) [0];
					gooc_img_uri = gooc_img_uri.split ("<img src=", 2) [1];
					gooc_img_uri = gooc_img_uri.split (" ", 2) [0];
					print ("FOUND gooc_img_uri: %s\n", gooc_img_uri);

					// original image uri
					orig_img_uri = line.split ("&imgrefurl", 2) [0];
					orig_img_uri = orig_img_uri.split ("?imgurl=", 2) [1];
					// clean google mess! why do they have % replaced by %25 ?
					orig_img_uri = orig_img_uri.replace ("%25", "%");
					print ("FOUND orig_img_uri: %s\n", orig_img_uri);
				}
			}
		} catch (IOError e) {
			error ("%s\n", e.message);
		}

		try {
			Thread.create (set_albumimage_from_goo, false);
		} catch (ThreadError e) {
			error ("%s\n", e.message);
		}
	}


	
	public static void* set_albumimage_from_goo () {
		//TODO: check if uri not 404 ?

		Gdk.threads_enter ();
		albumimage_overlay.set_from_file (working_animation);
		Gdk.flush ();
		Gdk.threads_leave ();
		
		if (gooc_img_uri != "") {
			set_albumimage_from_uri (gooc_img_uri);
		}

		if (orig_img_uri != "") {
			set_albumimage_from_uri (orig_img_uri);
		}
		
		Gdk.threads_enter ();
		albumimage_overlay.clear ();
		Gdk.flush ();
		Gdk.threads_leave ();

	    return null;
	}
	
	static void set_albumimage_from_uri (string uri) {
		File urifile;
		int width;
		int height;
		
		urifile = File.new_for_uri (uri);
		albumimage.get_size_request (out width, out height);

		print ("TRY TO SET IMAGE FROM: %s\n", uri);		
		print ("gtk.image dimensions: %ix%i\n", width, height);

		try {
			var in_stream = new GLib.DataInputStream (urifile.read (null));
			//var pix = new Gdk.Pixbuf.from_stream (in_stream, null);
			var pix = new Gdk.Pixbuf.from_stream_at_scale
					(in_stream, width, height, false, null);
			
			Gdk.threads_enter ();
			albumimage.set_from_pixbuf (pix);
			Gdk.flush ();
			Gdk.threads_leave ();
		
		} catch (IOError ex) {
			print ("get image error: %s\n", ex.message);
			//TODO set error/default image
		}
		print ("done setting image\n");
	}
	
	private string goo_encode (string str) {
		var s = GLib.Uri.escape_string (str, "", true);
		s = s.replace ("%20", "+");
		return s;
	}
}

