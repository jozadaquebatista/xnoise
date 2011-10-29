/* pl-xspf-file-reader.vala
 *
 * Copyright(C) 2010  Jörn Magens
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or(at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Francisco Pérez Cuadrado <fsistemas@gmail.com>
 * 	Jörn Magens <shuerhaaken@googlemail.com>
 */

using Xnoise.SimpleMarkup;

namespace Xnoise.Playlist {
	private class Xspf.FileReader : AbstractFileReader {
		private unowned File file;

		private EntryCollection parse(EntryCollection item_collection,
			                         ref string data) throws GLib.Error {
			Playlist.Entry d = null;
			SimpleMarkup.Reader reader = new SimpleMarkup.Reader.from_string(data);
			reader.read();
			var root = reader.root;
			if(root != null && root.has_children()) {
				var playlist = root[0];
				if(playlist != null && playlist.name.down() == "playlist" && playlist.has_children()) {
					SimpleMarkup.Node trackList = playlist[0];
					if(trackList != null && trackList.name.down() == "tracklist" && trackList.has_children()) {
						SimpleMarkup.Node[] tracks = trackList.get_children_by_name("track");
						if(tracks != null && tracks.length > 0) {
							foreach(SimpleMarkup.Node track in tracks) {
								if(track.has_children()) {
									d = new Playlist.Entry();
									var title = track.get_child_by_name("title");
									if(title != null) {
										d.add_field(Entry.Field.TITLE, title.text);
									}
									var location = track.get_child_by_name("location");
									if(location != null) {
										TargetType tt;
										File tmp = get_file_for_location(location.text, ref base_path, out tt);
										d.target_type = tt;
										d.add_field(Entry.Field.URI, tmp.get_uri());
										string? ext = get_extension(tmp);
										if(ext != null) {
											if(is_known_playlist_extension(ref ext))
												d.add_field(Entry.Field.IS_PLAYLIST, "1"); //TODO: handle recursion !?!?
										}
									}
									item_collection.append(d);
								}
							}
						}
					}
				}
			}
			return item_collection;
		}

		public override EntryCollection read(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			EntryCollection item_collection = new EntryCollection();
			this.file = _file;
			set_base_path();

			if(!file.get_uri().has_prefix("http://") && !file.query_exists (null)) {
				stderr.printf("File '%s' doesn't exist.\n", file.get_uri());
				return item_collection;
			}
		
			try {
				string contenido;
				var stream = new DataInputStream(file.read(null));
				contenido = stream.read_until("", null, null);
			
				if(contenido == null) {
					return item_collection;
				}
				//print("\n%s\n",contenido);
				return this.parse(item_collection, ref contenido); //ref base_path,
			}
			catch(GLib.Error e) {
				print ("%s\n", e.message);
			}
			return item_collection;
		}

		public override async EntryCollection read_asyn(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			var item_collection = new EntryCollection();
			this.file = _file;
			set_base_path();
			var mr = new SimpleMarkup.Reader(file);
			yield mr.read_asyn(); //read not case sensitive (lowercase)
			if(mr.root == null) {
				throw new InternalReaderError.INVALID_FILE("internal error with async xspf reading\n");
			}
			
			//get xspf root node
			unowned SimpleMarkup.Node? playlist = mr.root.get_child_by_name("playlist");
			if(playlist == null) {
				throw new InternalReaderError.INVALID_FILE("internal error with async xspf reading\n");
			}
			
			unowned SimpleMarkup.Node? xspf_tmp = null;
			
			// playlist title
			xspf_tmp = playlist.get_child_by_name("title");
			if(xspf_tmp != null && xspf_tmp.text != null)
				item_collection.add_general_info("title", xspf_tmp.text);
			
			// playlist info
			xspf_tmp = playlist.get_child_by_name("info");
			if(xspf_tmp != null && xspf_tmp.text != null)
				item_collection.add_general_info("info", xspf_tmp.text);
			
			// playlist creator
			xspf_tmp = playlist.get_child_by_name("creator");
			if(xspf_tmp != null && xspf_tmp.text != null)
				item_collection.add_general_info("creator", xspf_tmp.text);
			
			// playlist location
			xspf_tmp = playlist.get_child_by_name("location");
			if(xspf_tmp != null && xspf_tmp.text != null)
				item_collection.add_general_info("location", xspf_tmp.text);
			
			// playlist identifier
			xspf_tmp = playlist.get_child_by_name("identifier");
			if(xspf_tmp != null && xspf_tmp.text != null)
				item_collection.add_general_info("identifier", xspf_tmp.text);
			
			// playlist image
			xspf_tmp = playlist.get_child_by_name("image");
			if(xspf_tmp != null && xspf_tmp.text != null)
				item_collection.add_general_info("image", xspf_tmp.text);
			
			xspf_tmp = playlist.get_child_by_name("tracklist"); // here: lower case !!! "trackList"
			if(xspf_tmp == null) {
				throw new InternalReaderError.INVALID_FILE("internal error 2 with async xspf reading. No entries\n");
			}
			
			//get all entry nodes
			SimpleMarkup.Node[] entries = xspf_tmp.get_children_by_name("track");
			if(entries == null) {
				throw new InternalReaderError.INVALID_FILE("internal error 3 with async xspf reading. No entries\n");
			}

			foreach(unowned SimpleMarkup.Node nd in entries) {
				Entry d = new Entry();

				unowned SimpleMarkup.Node tmp = nd.get_child_by_name("location");
				if(tmp == null)
					continue; //error?

				string? target = null;
				
				if(tmp.has_text())
					target = tmp.text;

				if(target != null) {
					TargetType tt;
					File f = get_file_for_location(target._strip(), ref base_path, out tt);
					d.target_type = tt;
					//print("\nxspf read uri: %s\n", f.get_uri());
					d.add_field(Entry.Field.URI, f.get_uri());
					string? ext = get_extension(f);
					if(ext != null) {
						if(is_known_playlist_extension(ref ext))
							d.add_field(Entry.Field.IS_PLAYLIST, "1"); //TODO: handle recursion !?!?
					}
				}
				else
					continue;
		
				tmp = nd.get_child_by_name("title");
				if(tmp != null && tmp.has_text()) {
					d.add_field(Entry.Field.TITLE, tmp.text);
				}
				
				item_collection.append(d);
			}
			Idle.add( () => {
				this.finished(file.get_uri());
				return false;
			});
			return item_collection;
		}
	
		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}

