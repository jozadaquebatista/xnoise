/* pl-wpl-file-reader.vala
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

using Xnoise.SimpleXml;

namespace Xnoise.Pl {
	private class Wpl.FileReader : AbstractFileReader {
		private unowned File file;
		private ItemCollection parse(ItemCollection data_collection,ref string base_path, string data) throws GLib.Error {
			SimpleXml.Reader reader = new SimpleXml.Reader.from_string(data);
			reader.read();
			
			var root = reader.root;
			if(root != null && root.has_children()) {
			var smil = root[0];
			if(smil != null && smil.name.down() == "smil" && smil.has_children()) {
				//print("smil: %s\n",smil.name.down());
				var body = smil.get_child_by_name("body");
				if(body != null && body.has_children()) {
					Pl.Item d = null;
					//print("body: %s\n",body.name.down());
					var seq = body.get_child_by_name("seq");
					if(seq != null && seq.has_children()) {
						//print("seq: %s\n",seq.name.down());
						SimpleXml.Node[] medias = 
						seq.get_children_by_name("media");

						if(medias != null && medias.length>0) {
							foreach(SimpleXml.Node media in medias) {
								var attrs = media.attributes;
								if(attrs != null) {
									string src = attrs.get("src");
									if(src != null ) {
										d = new Pl.Item();
										TargetType tt;
										File tmp = get_file_for_location(src, ref base_path, out tt);
										d.target_type = tt;
										d.add_field(Item.Field.URI, tmp.get_uri());
										string? ext = get_extension(tmp);
										if(ext != null) {
											if(is_known_playlist_extension(ref ext)) {
												d.add_field(Item.Field.IS_PLAYLIST, "1"); //TODO: handle recursion !?!?
											}
										}
										data_collection.append(d);
									}
								}
							}
						}
					}
				}
			}
			

			var head = smil.get_child_by_name("head");
			if(head != null && head.has_children()) {
				//Playlist title
				var title = head.get_child_by_name("title");
				if(title != null) {
				//data_collection.add_field(Item.Field.TITLE, title.text);
				}
				
				//Playlist author
				var author = head.get_child_by_name("author");
				if(author != null) {
				//data_collection.add_field(Item.Field.AUTHOR, author.text);
				}

				SimpleXml.Node[] metas = head.get_children_by_name("meta");
				if(metas != null && metas.length > 0) {
					foreach(SimpleXml.Node meta in metas) {
						var attrs = meta.attributes;
						if(attrs != null) {
							string name = attrs.get("name");
							string content = attrs.get("content");
							if(name != null && content != null) {
								//TODO: More info from playlist
							}
						}
					}
				}
			}

			}
			return data_collection;
		}

		public override ItemCollection read(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			ItemCollection data_collection = new ItemCollection();
			this.file = _file;
			set_base_path();

			if(!file.get_uri().has_prefix("http://") && !file.query_exists(null)) {
				stderr.printf("File '%s' doesn't exist.\n",file.get_uri());
				return data_collection;
			}

			try {

				string content;
				var stream = new DataInputStream(file.read(null));
				content = stream.read_until("", null, null);

				if(content == null) {
					return data_collection;
				}

				//Replace wpl by xml
				content = content.replace("?wpl","?xml");

				//print("\n%s\n",content);
				return this.parse(data_collection,ref base_path,content);
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
			return data_collection; 
		}
	
		public override async ItemCollection read_asyn(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			var data_collection = new ItemCollection();
			this.file = _file;
			set_base_path();
			var mr = new SimpleXml.Reader(file);
			yield mr.read_asyn(false); //read not case sensitive
			if(mr.root == null) {
				throw new InternalReaderError.INVALID_FILE("internal error with async wpl reading\n");
			}
			
			//get asx root node
			unowned SimpleXml.Node wpl_base = mr.root.get_child_by_name("smil");
			if(wpl_base == null) {
				throw new InternalReaderError.INVALID_FILE("internal error with async wpl reading\n");
			}
			//print("children: %d\n", wpl_base.children_count);
			//print("name: %s\n", wpl_base.name);
			
			unowned SimpleXml.Node tmp;
			unowned SimpleXml.Node tmp_head;
			
			tmp_head = wpl_base.get_child_by_name("head");

			tmp = tmp_head.get_child_by_name("author");
			if(tmp != null && tmp.text != null)
				data_collection.add_general_info("author", tmp.text);
			
			tmp = tmp_head.get_child_by_name("title");
			if(tmp != null && tmp.text != null)
				data_collection.add_general_info("title", tmp.text);

			SimpleXml.Node[] metas = tmp_head.get_children_by_name("meta");
			if(metas != null) {
				foreach(unowned SimpleXml.Node nx in metas) {
					if(nx.attributes["name"] != null && nx.attributes["content"] != null)
						data_collection.add_general_info(nx.attributes["name"], nx.attributes["content"]);
				}
			}
			
			tmp = wpl_base.get_child_by_name("body");
			if(tmp == null) {
				throw new InternalReaderError.INVALID_FILE("internal error 2 with async wpl reading. No entries\n");
			}
			tmp = tmp.get_child_by_name("seq");
			SimpleXml.Node[] entries = tmp.get_children_by_name("media");
			if(entries == null) {
				throw new InternalReaderError.INVALID_FILE("internal error 3 with async wpl reading. No entries\n");
			}
			
			foreach(unowned SimpleXml.Node nd in entries) {
				Item d = new Item();
				
				string? target = null;
				target = nd.attributes["src"];

				if(target != null) {
					TargetType tt;
					File f = get_file_for_location(target._strip(), ref base_path, out tt);
					d.target_type = tt;
					//print("\nasx read uri: %s\n", f.get_uri());
					d.add_field(Item.Field.URI, f.get_uri());
					string? ext = get_extension(f);
					if(ext != null) {
						if(is_known_playlist_extension(ref ext))
							d.add_field(Item.Field.IS_PLAYLIST, "1"); //TODO: handle recursion !?!?
					}
				}
				else
					continue;
				
				data_collection.append(d);
			}
			Idle.add( () => {
				this.finished(file.get_uri());
				return false;
			});
			return data_collection;
		}

		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}
