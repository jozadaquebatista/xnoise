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

using Xml;
using SimpleXml;

namespace Pl {
	private class Xspf.FileReader : AbstractFileReader {
		private unowned File file;

		private ItemCollection parse(ItemCollection item_collection,
			                         ref string data) throws GLib.Error {
			Pl.Item d = null;
			SimpleXml.Reader reader = new SimpleXml.Reader.from_string(data);
			reader.read();
			var root = reader.root;
			if(root != null && root.has_children()) {
				var playlist = root[0];
				if(playlist != null && playlist.name.down() == "playlist" && playlist.has_children()) {
					SimpleXml.Node trackList = playlist[0];
					if(trackList != null && trackList.name.down() == "tracklist" && trackList.has_children()) {
						SimpleXml.Node[] tracks = trackList.get_children_by_name("track");
						if(tracks != null && tracks.length > 0) {
							foreach(SimpleXml.Node track in tracks) {
								if(track.has_children()) {
									d = new Pl.Item();
									var title = track.get_child_by_name("title");
									if(title != null) {
										d.add_field(Item.Field.TITLE, title.text);
									}
									var location = track.get_child_by_name("location");
									if(location != null) {
										TargetType tt;
										File tmp=get_file_for_location(location.text, ref base_path, out tt);
										d.target_type = tt;
										d.add_field(Item.Field.URI, tmp.get_uri());
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

		public override ItemCollection read(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			ItemCollection item_collection = new ItemCollection();
			this.file = _file;
			set_base_path();

			if(!file.get_uri().has_prefix("http://") && !file.query_exists (null)) {
				stderr.printf("File '%s' doesn't exist.\n",file.get_uri());
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

		public override async ItemCollection read_asyn(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			ItemCollection item_collection = new ItemCollection();
			this.file = _file;
			set_base_path();
			return item_collection;
		}
	
		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}

