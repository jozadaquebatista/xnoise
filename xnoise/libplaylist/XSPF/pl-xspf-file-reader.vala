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

namespace Pl {
	// base class for all playlist filereader implementations
	private class Xspf.FileReader : AbstractFileReader {
		private unowned File file;

		private DataCollection parse(DataCollection data_collection,ref string base_path = "",string data) throws GLib.Error {
		string iter_name;
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		Xml.Node* rootNode = xmlDoc->get_root_element();
		Pl.Data d = null;
		for(Xml.Node* iter=rootNode->children; iter!=null;iter=iter->next) {
			if(iter->type != ElementType.ELEMENT_NODE) {
				  continue;
			}
		
			iter_name = iter->name.down(); 
			if(iter_name == "tracklist") {
			        //print("\nTrackList: %s\n","trackList");
				if(iter->children != null) {
					Xml.Node *iter_in;   
     				for(iter_in = iter->children->next; iter_in != null;iter_in = iter_in->next) {
							if(iter_in->is_text() == 0) {
								switch(iter_in->name.down()) {
									case "track":
										if(iter_in->children != null) {
											Xml.Node *seq_in;
											d = new Pl.Data();
											for(seq_in=iter_in->children->next;seq_in!=null;seq_in=seq_in->next) 
											{
												if(seq_in->is_text() == 0) {
													switch(seq_in->name.down()) {
														case "location": {
														 string url = seq_in->get_content();
														 //print("URL = '%s'\n",url);
														 TargetType tt;
														 File tmp = get_file_for_location(url, ref base_path, out tt);
														 d.target_type = tt;
														 d.add_field(Data.Field.URI, tmp.get_uri());
														}
														break;
														case "title": {
															//print("%s = '%s'\n",seq_in->name,seq_in->get_content());
															d.add_field(Data.Field.TITLE,seq_in->get_content());
														}
														break;
														case "default": {}
														break;
													}
												}
												//delete seq_in;
											}
											//ADD
											data_collection.append(d);
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
				} else {
				        //print("\nOtro:%s\n",iter_name);
				}
			}
			return data_collection;
		}

	public override DataCollection read(File _file) throws InternalReaderError {
			DataCollection data_collection = new DataCollection();
			this.file = _file;
			set_base_path();
	    
			if (!file.get_uri().has_prefix("http://") && !file.query_exists (null)) {
				stderr.printf("File '%s' doesn't exist.\n",file.get_uri());
				return data_collection;
			}
	    	    	     
	    try {
				string contenido;
				{
					var stream = new DataInputStream(file.read(null));
					contenido = stream.read_until("", null, null);
				}
			  
			  if(contenido == null) {
			    return data_collection;
			  }
				//print("\n%s\n",contenido);
				return this.parse(data_collection,ref base_path,contenido);
	    }
	    catch (GLib.Error e) {
				print ("%s\n", e.message);
	    }
	    return data_collection; 
	  }

		//public override DataCollection read(File _file) throws InternalReaderError {
		public DataCollection read_txt(File _file) throws InternalReaderError {
			DataCollection data_collection = new DataCollection();
			this.file = _file;
			set_base_path();
			
			var entry_on = false;
		
			if(!file.query_exists(null)) {
				stderr.printf("File '%s' doesn't exist.\n", file.get_uri());
				return data_collection;
			}
			try {
				var in_stream = new DataInputStream(file.read(null));
				string line;
				Data? d = null;
				while((line = in_stream.read_line(null, null)) != null) {
					if(line.has_prefix("#")) { //# Comments
						continue;
					}
					else if(line.size() == 0) { //Blank line
						continue;
					}
					else if(line.contains("<track>")) {
						entry_on = true;
						//print("prepare new entry\n");
						d = new Data();
						continue;
					}
					else if(line.contains("</track>")) {
						entry_on = false;
						//print("add entry\n");
						data_collection.append(d);
						continue;
					}
					else if(entry_on) { // Can we always assume that this is in one line???
						if(line.contains("<location")) {
							char* begin = line.str(">");
							begin ++;
							char* end = line.rstr("<");
							if(begin >= end) {
								throw new InternalReaderError.INVALID_FILE("Error. Invalid playlist file (uri)\n");
							}
							*end = '\0';

							TargetType tt;
							File tmp = get_file_for_location(((string)begin)._strip(), ref base_path, out tt);
							d.add_field(Data.Field.URI, tmp.get_uri());
							d.target_type = tt;
						}
						if(line.contains("<title")) {
							char* begin = line.str(">");
							begin++;
							char* end = line.rstr("<");
							if(begin >= end) {
								throw new InternalReaderError.INVALID_FILE("Error. Invalid playlist file (title)\n");
							}
							*end = '\0';
							d.add_field(Data.Field.TITLE, ((string)begin)._strip());
						}
					}
					else {
						continue;
					}
				}
			}
			catch(GLib.Error e) {
				print("Error: %s\n", e.message); 
			}
			return data_collection;
		}

		public override async DataCollection read_asyn(File _file) throws InternalReaderError {
			DataCollection data_collection = new DataCollection();
			this.file = _file;
			set_base_path();
			return data_collection;
		}
		
		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}

