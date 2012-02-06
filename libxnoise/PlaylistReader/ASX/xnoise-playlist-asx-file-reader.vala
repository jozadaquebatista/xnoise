/* pl-asx-file-reader.vala
 *
 * Copyright(C) 2010-2012  Jörn Magens
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
 * 	Francisco Pérez Cuadrado <fsistemas@gmail.com>
 * 	Jörn Magens <shuerhaaken@googlemail.com>
 */

using Xnoise;
using Xnoise.Services;
using Xnoise.SimpleMarkup;

namespace Xnoise.Playlist {
	private class Asx.FileReader : AbstractFileReader {
		private unowned File file;

		public string fix_tags_xml(string content) {
			string up;
			string down;
			string xml=content;
			MatchInfo match_info = null;
			string[] result;
			Regex regex = null;
			
			try {
				regex = new Regex("(<([A-Z]+[A-Za-z0-9]+))|(<\\/([A-Z]+([A-Za-z0-9])+)>)");
			}
			catch(GLib.RegexError e) {
				print("%s\n", e.message);
			}
			while(regex.match_all(xml,0,out match_info)) {
				result = match_info.fetch_all ();
				if(result!=null && result.length > 0) {
					up = result[0].up();
					down = result[0].down();
					xml = xml.replace(result[0],down);
					xml = xml.replace(up,down);
				}
			}
			return xml;
		}

		private EntryCollection parse(EntryCollection data_collection,ref string base_path, string data) {
			SimpleMarkup.Reader reader = new SimpleMarkup.Reader.from_string(data);
			reader.read();
			var root = reader.root;
			if(root != null && root.has_children()) {
				var asx = root[0];
				//print("asx: %s\n",asx.name.down());
				if(asx != null && asx.has_children() && "asx"==asx.name.down()) {
					var ptitle = asx.get_child_by_name("title");
					//Playlist title
					if(ptitle != null) {
						//ptitle.text
					}
					var entrys = asx.get_children_by_name("entry");
					if(entrys != null && entrys.length>0) {
						Playlist.Entry d = null;
						foreach(SimpleMarkup.Node entry in entrys) {
							d = new Playlist.Entry();
							var title = entry.get_child_by_name("title");
							if(title != null) {
								d.add_field(Entry.Field.TITLE,title.text);
							}
							//Autor
							var author = entry.get_child_by_name("author");
							if(author != null) {
								//author.text
							}
							//Copyright
							var copyright = entry.get_child_by_name("copyright");
							if(copyright != null) {
								//copyright.text
							}
							var xref = entry.get_child_by_name("ref");
							if(xref!=null && xref.attributes != null) {
								var attrs = xref.attributes;
								var href = attrs.get("href");
								if(href!= null) {
									TargetType tt;
									File tmp = get_file_for_location(href, ref base_path, out tt);
									d.target_type = tt;
									d.add_field(Entry.Field.URI, tmp.get_uri());
									string? ext = get_extension(tmp);
									if(ext != null) {
										if(is_known_playlist_extension(ref ext)) {
											d.add_field(Entry.Field.IS_PLAYLIST, "1"); //TODO: handle recursion !?!?
										}
									}
									data_collection.append(d);
								}
							}
						}
					}
				}
			}
			
			return data_collection;
		}

		//public EntryCollection read_xml(File _file) throws InternalReaderError {
		public override EntryCollection read(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			EntryCollection data_collection = new EntryCollection();
			this.file = _file;
			set_base_path();
			
			if (!file.get_uri().has_prefix("http://") && !file.query_exists (null)) {
				stderr.printf("File '%s' doesn't exist.\n",file.get_uri()); //THROW
				return data_collection;
			}
			
			try {
				string content;
				var stream = new DataInputStream(file.read(null));
				content = stream.read_until(EMPTYSTRING, null, null);
			
				if(content == null) {
					return data_collection;
				}
				content = this.fix_tags_xml(content);
				//print("\n\n%s: \n\n",content);
				content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + content;
				this.parse(data_collection,ref base_path,content);
			} 
			catch(GLib.Error e) {
				print("Error: %s\n", e.message);
			}
			return data_collection;
		}

		public override async EntryCollection read_asyn(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			var data_collection = new EntryCollection();
			this.file = _file;
			set_base_path();
			var mr = new SimpleMarkup.Reader(file);
			yield mr.read_asyn(); //read not case sensitive
			if(mr.root == null) {
				throw new InternalReaderError.INVALID_FILE("internal error with async asx reading\n");
			}
			
			//get asx root node
			unowned SimpleMarkup.Node asx_base = mr.root.get_child_by_name("asx");
			if(asx_base == null) {
				throw new InternalReaderError.INVALID_FILE("internal error with async asx reading\n");
			}
			//print("children: %d\n", asx_base.children_count);
			//print("name: %s\n", asx_base.name);
			
			//get all entry nodes
			SimpleMarkup.Node[] entries = asx_base.get_children_by_name("entry");
			if(entries == null) {
				throw new InternalReaderError.INVALID_FILE("internal error 2 with async asx reading. No entries\n");
			}
			
			foreach(unowned SimpleMarkup.Node nd in entries) {
					Entry d = new Entry();

					unowned SimpleMarkup.Node tmp = nd.get_child_by_name("ref");
					if(tmp == null)
						continue; //error?

					string? target = null;
					if(tmp != null)
						target = tmp.attributes["href"];

					if(target != null) {
						TargetType tt;
						File f = get_file_for_location(target._strip(), ref base_path, out tt);
						d.target_type = tt;
						//print("\nasx read uri: %s\n", f.get_uri());
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

