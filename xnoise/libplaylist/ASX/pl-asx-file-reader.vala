/* pl-asx-file-reader.vala
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

namespace Pl {
	private class Asx.FileReader : AbstractFileReader {
		private unowned File file;

		public string fix_tags_xml(string content) {
			string up;
			string down;
			string xml=content;
			MatchInfo match_info = null;
			string[] resultado;
			Regex regex = null;
			
			try {
				regex = new Regex("(<([A-Z]+[A-Za-z0-9]+))|(<\\/([A-Z]+([A-Za-z0-9])+)>)");
			}
			catch(GLib.RegexError e) {
				print("%s\n", e.message);
			}
			while(regex.match_all(xml,0,out match_info)) {
				resultado = match_info.fetch_all ();
				if(resultado!=null && resultado.length > 0) {
					up = resultado[0].up();
					down = resultado[0].down();
					xml = xml.replace(resultado[0],down);
					xml = xml.replace(up,down);
				}
			}
			return xml;
		}

		private ItemCollection parse(ItemCollection data_collection,ref string base_path = "",string data) {
			string iter_name;
			Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
			Xml.Node* rootNode = xmlDoc->get_root_element();

			Pl.Item d = null;
			for(Xml.Node* iter = rootNode->children; iter != null; iter = iter->next) {
				if(iter->type != ElementType.ELEMENT_NODE) {
					continue;
				}
				iter_name = iter->name.down();
				if(iter_name == "entry") {
					if(iter->children != null) {
						Xml.Node *iter_in;
						for(iter_in=iter->children->next;iter_in != null; iter_in = iter_in->next) {
							if(iter_in->is_text() == 0) {
								switch(iter_in->name.down()) {
									case "ref":
										string href = iter_in->get_prop("href");
										//print("URL = '%s'\n",href);
										d = new Pl.Item();
										TargetType tt;
										File tmp = get_file_for_location(href, ref base_path, out tt);
										d.target_type = tt;
										d.add_field(Item.Field.URI, tmp.get_uri());
										data_collection.append(d);
										break;
									case "title":
										//print("Title = '%s'\n",iter_in->get_content());
										//d.add_field(Item.Field.TITLE,iter_in->get_content());
										break;
									case "author":
										//print("Autor = '%s'\n",iter_in->get_content());
										break;
									case "copyright":
										//print("Copyright = '%s'\n",iter_in->get_content());
										break;
									default:
										//print("%s = '%s'\n",iter_in->name,iter_in->get_content());
										break;
								}
							}
						}
						delete iter_in;
					}
				}
				else if(iter_name == "title") {
					//print("Playlist Title = '%s'\n",iter->get_content());
				}
			}
			return data_collection;
		}

		//public ItemCollection read_xml(File _file) throws InternalReaderError {
		public override ItemCollection read(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			ItemCollection data_collection = new ItemCollection();
			this.file = _file;
			set_base_path();
			
			if (!file.get_uri().has_prefix("http://") && !file.query_exists (null)) {
				stderr.printf("File '%s' doesn't exist.\n",file.get_uri()); //THROW
				return data_collection;
			}
			
			try {

				string content;
				var stream = new DataInputStream(file.read(null));
				content = stream.read_until("", null, null);
			
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

		public override async ItemCollection read_asyn(File _file, Cancellable? cancellable = null) throws InternalReaderError {
			var data_collection = new ItemCollection();
			this.file = _file;
			set_base_path();
			var mr = new SimpleXml.Reader(file);
			yield mr.read_asyn(false); //read not case sensitive
			if(mr.root == null) {
				throw new InternalReaderError.INVALID_FILE("internal error with async asx reading\n");
			}
			
			//get asx root node
			unowned SimpleXml.Node asx_base = mr.root.get_child_by_name("asx");
			if(asx_base == null) {
				throw new InternalReaderError.INVALID_FILE("internal error with async asx reading\n");
			}
			//print("children: %d\n", asx_base.children_count);
			//print("name: %s\n", asx_base.name);
			
			//get all entry nodes
			SimpleXml.Node[] entries = asx_base.get_children_by_name("entry");
			if(entries == null) {
				throw new InternalReaderError.INVALID_FILE("internal error 2 with async asx reading. No entries\n");
			}
			
			foreach(unowned SimpleXml.Node nd in entries) {
					Item d = new Item();

					unowned SimpleXml.Node tmp = nd.get_child_by_name("ref");
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
						d.add_field(Item.Field.URI, f.get_uri());
					}
					else
						continue;
			
					tmp = nd.get_child_by_name("title");
					if(tmp != null && tmp.has_text()) {
						d.add_field(Item.Field.TITLE, tmp.text);
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

