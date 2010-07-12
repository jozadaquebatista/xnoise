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
		
		public override Data? read(File _file) throws ReaderError {
			Data data = new Data();//weiter runter
			this.file = _file;
			string[] list = {};
			var entry_on = false;
		
			if (!file.get_uri().has_prefix("http://") && !file.query_exists (null)) {
				stderr.printf("File '%s' doesn't exist.\n",file.get_uri());
				return data;
			}
		
			try {
				var in_stream = new DataInputStream(file.read(null));
				string line;
				while((line = in_stream.read_line(null, null)) != null) {
					if(line.has_prefix("#")) { //# Comments
						continue;
					}
					else if(line.size() == 0) { //Blank line
						continue;
					}
					else if(line.contains("<entry>")) {
						entry_on = true;
						continue;
					}
					else if(line.contains("</entry>")) {
						entry_on = false;
						continue;
					}
					else {
						if(entry_on) {
							if(line.contains("<ref")) {
								string[] array_ref = line.split("\"");
								if(array_ref != null && array_ref.length == 3) {
									list+=array_ref[1];
								}
							}
						}
					}
				}
			} 
			catch(GLib.Error e) {
				stdout.printf("Errorr: %s\n", e.message);
			}
			data.urls = list;
			return data;
		}

		public override async Data? read_asyn(File _file) throws ReaderError {
			this.file = _file;
			return null;
		}
	}
}

