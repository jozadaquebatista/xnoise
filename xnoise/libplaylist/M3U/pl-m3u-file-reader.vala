/* pl-m3u-file-reader.vala
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
	// base class for all playlist filereader implementations
	private class M3u.FileReader : AbstractFileReader {
		private unowned File file;
		private string[] lines_buf;
		
		construct {
			lines_buf = {};
		}
		
		public override DataCollection read(File _file) throws InternalReaderError {
			DataCollection data_collection = new DataCollection();
			this.file = _file;
			set_base_path();
			
			if(!file.query_exists(null)) {
				stderr.printf("File '%s' doesn't exist.\n", file.get_uri());
				return data_collection;
			}

			try {
				var in_stream = new DataInputStream(file.read(null));
				string line;

				//Read header => #M3U o #EXTM3U
				if((line = in_stream.read_line(null, null)) != null) {

					//Process file only if it's valid m3u play list
					if(line.has_prefix("#M3U") || line.has_prefix("#EXTM3U")) {
						// Read lines until end of file(null) is reached
						while((line = in_stream.read_line(null, null)) != null && line != "#EXT-X-ENDLIST") {
							if(line._strip().size() == 0)
								continue;
								
							lines_buf += line._strip();
						}
						Data d = null;
						for(int i = 0; i < lines_buf.length && lines_buf[i] != null;i++) {
							string title = "";
							string adress = "";
							if(line_is_comment(ref lines_buf[i])) {
								if(!line_is_extinf(ref lines_buf[i], ref title)) {
									continue;
								}
								else {
									// here it's an extinf
									// look into the following lines
									for(int j = i + 1; j < lines_buf.length && lines_buf[j] != null; j++) {
										if(line_is_comment(ref lines_buf[j])) {
											//is comment
											if(line_is_extinf(ref lines_buf[j], ref title)) {
												//is extinf, so it is used and adress is deleted
												i = j;
												adress = "";
												break;
											}
										}
										else {
											adress = lines_buf[j];
											d = new Data();
											i = j;
											break;
										}
									}
								}
							}
							else {
								//then it's an adress
								adress = lines_buf[i];
								d = new Data();
							}
							if(adress != "") {
								TargetType tt;
								File tmp = get_file_for_location(adress, ref base_path, out tt);
								d.add_field(Data.Field.URI, tmp.get_uri());
								d.target_type = tt;
								if(title != "") {
									d.add_field(Data.Field.TITLE, title);
								}
								data_collection.append(d);
							}
						}
					}
				}
			}
			catch(GLib.Error e) {
				print("%s", e.message);
			}
			return data_collection;
		}
		
		private bool line_is_comment(ref string line) {
			if(line.has_prefix("#"))
				return true;
			
			return false;
		}
		
		private bool line_is_extinf(ref string line, ref string title) {
			if(line.has_prefix("#EXTINF:")) {
				char* begin = line.str("#EXTINF:");
				char* end = (char*)line + line.size();
				begin++;
				if(begin >= end) {
					print("error reading EXTINF\n");
					title = "";
					return true;
				}
				if(((string)begin).contains(",")) {
					begin = ((string)begin).str(",");
					begin++;
					title = ((string)begin)._strip();
					return true;
				}
				else {
					title = "";
					return true;
				}
			}
			return false;
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

