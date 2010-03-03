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
//TODO: use priorities
public class Xnoise.AlbumImageLoader : GLib.Object {
	private static IAlbumCoverImageProvider provider;
	private static Main xn;
	private uint backend_iter;
	public string artist;
	public string album;
	
	public signal void sign_fetched(string artist, string album, string image_path);

	public AlbumImageLoader() {
		xn = Main.instance;
		xn.plugin_loader.sign_plugin_activated.connect(AlbumImageLoader.on_plugin_activated);
		backend_iter = 0;
	}

	private static void on_plugin_activated(Plugin p) {
		if(!p.is_album_image_plugin) 
			return;
		
		IAlbumCoverImageProvider provider = p.loaded_plugin as IAlbumCoverImageProvider;
		if(provider == null) 
			return;
		
		AlbumImageLoader.provider = provider;
		p.sign_deactivated.connect(AlbumImageLoader.on_backend_deactivated);
	}
	
	//forward signal from current provider
	private void on_image_fetched(string _artist, string _album, string _image_path) {
		sign_fetched(_artist, _album, _image_path);
	}

	private static void on_backend_deactivated() {
		AlbumImageLoader.provider = null;
	}

	public bool fetch_image() {
		if(this.provider == null) {
			sign_fetched("", "", "");
			return false;
		}
		Idle.add( () => {
			var album_image_provider = this.provider.from_tags(artist, album);
			if(album_image_provider == null)
				return false;
			album_image_provider.sign_image_fetched.connect(on_image_fetched);
			album_image_provider.ref(); //prevent destruction before ready
			album_image_provider.find_image();
			return false;
		});
		return true;
	}
}
