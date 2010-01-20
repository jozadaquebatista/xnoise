/* xnoise-album-image-loader.vala
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
 * 	softshaker  softshaker googlemail.com
 * 	Jörn Magens
 */

public class Xnoise.AlbumImageLoader : GLib.Object {
	public IAlbumCoverImage album_image_provider;
	private static IAlbumCoverImageProvider provider;
	private static Main xn;
	private uint backend_iter;
	private string artist;
	private string album;
	private static weak Thread fetcher_thread;
	public static Mutex mutex;
	
	public delegate IAlbumCoverImage AlbumImageCreatorDelg(string artist, string album);
	public signal void sign_fetched(string artist, string album, string? image_path);

	public static void init() {
		xn = Main.instance;
		mutex = new Mutex();
		xn.plugin_loader.sign_plugin_activated.connect(AlbumImageLoader.on_plugin_activated);
	}

	public AlbumImageLoader(string artist, string album) {
		this.artist = artist;
		this.album = album;
		backend_iter = 0;
	}

	private static void on_plugin_activated(Plugin p) {
		if(!p.is_album_image_plugin) return;
		IAlbumCoverImageProvider provider = p.loaded_plugin as IAlbumCoverImageProvider;
		if(provider == null) return;
		AlbumImageLoader.provider = provider;
		p.sign_deactivated.connect(AlbumImageLoader.on_backend_deactivated);
	}

	private static void on_backend_deactivated() {
		AlbumImageLoader.provider = null;
	}

	private static void on_done(IAlbumCoverImage instance) {
		mutex.lock();
		fetcher_thread = null;
		mutex.unlock();
		instance.unref();
	}

	private void on_fetched(string artist, string album, string? image_path) {
		sign_fetched(artist, album, image_path);
		this.album_image_provider = null;
	}

	public string get_image_uri() {
		return album_image_provider.get_image_uri();
	}

	public bool fetch_image() {
		if(this.provider == null) {
			sign_fetched("", "", null);
			return false;
		}

		this.album_image_provider = this.provider.from_tags(artist, album);
		this.album_image_provider.ref();
		this.album_image_provider.sign_album_image_fetched.connect(this.on_fetched);
		this.album_image_provider.sign_album_image_done.connect(on_done);
		try {
			mutex.lock();
			this.fetcher_thread = Thread.create(album_image_provider.fetch_image, true);
			mutex.unlock();
		}
		catch(GLib.ThreadError e) {
			print("Album image loader: %s", e.message);
		}
		return true;
	}
}
