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

using Xml;

namespace Pl {
	private class Wpl.FileReader : AbstractFileReader {
		private unowned File file;
		private DataCollection parse(DataCollection data_collection,ref string base_path = "",string data) throws GLib.Error {
			string iter_name;
			Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
			Xml.Node* rootNode = xmlDoc->get_root_element();
			Pl.Data d = null;
			for(Xml.Node* iter = rootNode->children; iter != null; iter = iter->next) {
				if(iter->type != ElementType.ELEMENT_NODE) {
					continue;
				}
			
				iter_name = iter->name.down(); 
				if(iter_name == "body") {
					if(iter->children != null) {
						Xml.Node *iter_in;
						for(iter_in = iter->children->next; iter_in != null;iter_in = iter_in->next) {
							if(iter_in->is_text() == 0) {
								switch(iter_in->name.down()) {
									case "seq":
										if(iter_in->children != null) {
											Xml.Node *seq_in;
											for(seq_in = iter_in->children->next;seq_in!=null;seq_in=seq_in->next) {
												if(seq_in->is_text() == 0) {
													switch(seq_in->name.down()) {
														case "media":
															d = new Pl.Data();
															string src = seq_in->get_prop("src");
															//print("URL = '%s'\n",src);
															TargetType tt;
															File tmp = get_file_for_location(src, ref base_path, out tt);
															d.target_type = tt;
															d.add_field(Data.Field.URI, tmp.get_uri());
															data_collection.append(d);
															break;
														case "default":
															break;
														default:
															break;
													}
												}
											//delete seq_in;
											}
										}
										break;
									default:
										//print("%s = '%s'\n",iter_in->name,iter_in->get_content());
										break;
								}
							}
								//delete iter_in;
						}
					}
				}
				else if(iter_name=="head") {
					if(iter->children != null) {
						Xml.Node *iter_in;
						for(iter_in=iter->children->next;iter_in!=null;iter_in=iter_in->next) {
							if(iter_in->is_text() == 0) {
								switch(iter_in->name.down()) {
									case "title": 
										//print("Play list title =  '%s'\n",iter_in->get_content());
										break;
									default:
										break;
								}
							}
							//delete iter_in;
						}
					}
				}
			}
			return data_collection;
		}

		public override DataCollection read(File _file) throws InternalReaderError {
			DataCollection data_collection = new DataCollection();
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
	
		public override async DataCollection read_asyn(File _file) throws InternalReaderError {
			var data_collection = new DataCollection();
			//TODO:
			return data_collection;
		}

		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}
