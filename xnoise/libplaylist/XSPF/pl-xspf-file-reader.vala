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

namespace Pl {
	// base class for all playlist filereader implementations
	private class Xspf.FileReader : AbstractFileReader {
		private unowned File file;
		
		public override Data? read(File _file) throws ReaderError {
			Data data = new Data();//weiter runter
			this.file = _file;
			
			string[] list = {};
			var entry_on = false;
		
			if(!file.get_uri().has_prefix("http://") && !file.query_exists(null)) {
				stderr.printf("File '%s' doesn't exist.\n", file.get_uri());
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
					else if(line.contains("<track>")) {
						entry_on = true;
						continue;
					} 
					else if(line.contains("</track>")) {
						entry_on = false;
						stdout.printf("\n");
						continue;
					} 
					else {
						if(entry_on) {
							if(line.contains("<location")) {
								line = line.replace("<location>","");
								line = line.replace("</location>","");
								line = line.strip();
								list+= line;
							}
						}
					}
				}
			} 
			catch(GLib.Error e) {
				stdout.printf("Error: %s\n", e.message); 
			}
			data.urls = list;
			return data;
		}

		public override async Data? read_asyn(File _file) throws ReaderError {
//			Data data = new Data();
			this.file = _file;
			return null;
		}
	}
}

