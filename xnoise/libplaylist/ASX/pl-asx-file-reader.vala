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

namespace Pl {
	private class Asx.FileReader : AbstractFileReader {
		private unowned File file;
		
		public override DataCollection read(File _file) throws InternalReaderError {
			DataCollection data_collection = new DataCollection();
			this.file = _file;
			set_base_path();
			
			bool entry_on = false;
		
			if (!file.get_uri().has_prefix("http://") && !file.query_exists (null)) {
				stderr.printf("File '%s' doesn't exist.\n",file.get_uri());
				return data_collection;
			}
		
			try {
				var in_stream = new DataInputStream(file.read(null));
				string line;
				Data d = null;
				while((line = in_stream.read_line(null, null)) != null) {
					char* begin;
					char* end;
					
					if(line.has_prefix("#")) { //# Comments
						continue;
					}
					else if(line.size() == 0) { //Blank line
						continue;
					}
					else if(line.contains("<entry>")) {
						d = new Data();
						entry_on = true;
						continue;
					}
					else if(line.contains("</entry>")) {
						entry_on = false;
						data_collection.append(d);
						continue;
					}
					else {
						if(entry_on) {
							if(line.contains("<ref")) {
								begin = line.str("\"");
								begin ++;
								end = line.rstr("\"");
								if(begin >= end) {
									print("no url inside\n");
									continue;
								}
								*end = '\0';
								//print("\nasx location %s\n", ((string)begin));
								TargetType tt;
								File tmp = get_file_for_location(((string)begin)._strip(), ref base_path, out tt);
								d.target_type = tt;
								//print("\nasx read uri: %s\n", tmp.get_uri());
								d.add_field(Data.Field.URI, tmp.get_uri());
							}
							else if(line.contains("<title>")) {
								begin = line.str("<title>");
								begin += "<title>".size();
								end = line.rstr("</title>");
								*end = '\0';
								d.add_field(Data.Field.TITLE, (string)begin);
							}
						}
					}
				}
			} 
			catch(GLib.Error e) {
				print("Errorr: %s\n", e.message);
			}
			return data_collection;
		}

//		private DataCollection data_collection;
		
		public override async DataCollection read_asyn(File _file) throws InternalReaderError {
			var data_collection = new DataCollection();
			this.file = _file;
			set_base_path();
			DataInputStream in_stream = null;
			bool entry_on = false;
			size_t a;
			started(file.get_uri());
			try {
//				di_stream = new DataInputStream(f.read(null));
				in_stream = new DataInputStream(file.read(null));
			}
			catch (GLib.Error e) {
				print("Error 01!\n");
			}
			string line = null;
			Data d = null;
			try {
				while(in_stream != null && (line = yield in_stream.read_line_async(GLib.Priority.DEFAULT, null, out a)) != null) {
//					line = yield di_stream.read_line_async(GLib.Priority.DEFAULT, null, out a);
					char* begin;
					char* end;
					
					if(line.has_prefix("#")) { //# Comments
						continue;
					}
					else if(line.size() == 0) { //Blank line
						continue;
					}
					else if(line.contains("<entry>")) {
						d = new Data();
						entry_on = true;
						continue;
					}
					else if(line.contains("</entry>")) {
						entry_on = false;
						data_collection.append(d);
						continue;
					}
					else {
						if(entry_on) {
							if(line.contains("<ref")) {
								begin = line.str("\"");
								begin ++;
								end = line.rstr("\"");
								if(begin >= end) {
									print("no url inside\n");
									continue;
								}
								*end = '\0';
								//print("\nasx location %s\n", ((string)begin));
								TargetType tt;
								File tmp = get_file_for_location(((string)begin)._strip(), ref base_path, out tt);
								d.target_type = tt;
								//print("\nasx read uri: %s\n", tmp.get_uri());
								d.add_field(Data.Field.URI, tmp.get_uri());
							}
							else if(line.contains("<title>")) {
								begin = line.str("<title>");
								begin += "<title>".size();
								end = line.rstr("</title>");
								*end = '\0';
								d.add_field(Data.Field.TITLE, (string)begin);
							}
						}
					}
				}
			}
			catch(GLib.Error err) {
					print("%s\n", err.message);
			}
			Idle.add( () => {
				this.finished(file.get_uri());
				return false;
			});
			return data_collection;
		}
		
//		private async void read_asyn_internal() throws InternalReaderError {
//			DataInputStream in_stream = null;
//			bool entry_on = false;
//			size_t a;
//			try {
////				di_stream = new DataInputStream(f.read(null));
//				in_stream = new DataInputStream(file.read(null));
//			}
//			catch (GLib.Error e) {
//				print("Error 01!\n");
//			}
//			string line;
//			Data d = null;
//			try {
//				while(in_stream != null && (line = yield in_stream.read_line_async(GLib.Priority.DEFAULT, null, out a)) != null) {
////					line = yield di_stream.read_line_async(GLib.Priority.DEFAULT, null, out a);

//					if(line.has_prefix("#")) { //# Comments
//						continue;
//					}
//					else if(line.size() == 0) { //Blank line
//						continue;
//					}
//					else if(line.contains("<entry>")) {
//						d = new Data();
//						entry_on = true;
//						continue;
//					}
//					else if(line.contains("</entry>")) {
//						entry_on = false;
//						data_collection.append(d);
//						continue;
//					}
//					else {
//						if(entry_on) {
//							if(line.contains("<ref")) {
//								char* begin = line.str("\"");
//								begin ++;
//								char* end = line.rstr("\"");
//								if(begin >= end) {
//									print("no url inside\n");
//									continue;
//								}
//								*end = '\0';
//								//print("\nasx location %s\n", ((string)begin));
//								TargetType tt;
//								File tmp = get_file_for_location(((string)begin)._strip(), ref base_path, out tt);
//								d.target_type = tt;
//								//print("\nasx read uri: %s\n", tmp.get_uri());
//								d.add_field(Data.Field.URI, tmp.get_uri());
//							}
//							else if(line.contains("<title>")) {
//								char* begin = line.str("<title>");
//								begin += "<title>".size();
//								char* end = line.rstr("</title>");
//								*end = '\0';
//								d.add_field(Data.Field.TITLE, (string)begin);
//							}
//						}
//					}
//				}
//			}
//			catch(GLib.Error e) {
//					print("%s\n", e.message);
//			}
//		}
		
		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}
