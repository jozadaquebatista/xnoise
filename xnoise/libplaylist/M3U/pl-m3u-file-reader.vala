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
		
		public override Data? read(File _file) throws ReaderError {
			//Data data = new Data();//weiter runter
			this.file = _file;
			
			string[] list = {};

			if(!file.query_exists(null)) {
				stderr.printf("File '%s' doesn't exist.\n", file.get_uri());
				return null;
			}

			try {
				var in_stream = new DataInputStream(file.read(null));
				string line;

				//Read header => #M3U o #EXTM3U
				if((line = in_stream.read_line(null, null)) != null) {

					//Process file only if it's valid m3u play list
					if(line.has_prefix("#M3U") || line.has_prefix("#EXTM3U")) {

						// Read lines until end of file(null) is reached
						while((line = in_stream.read_line(null, null)) != null) {

							//Ignorar lineas en blanco
							if(line.strip().size() == 0)
								continue;

							//TODO: Read aditional info
							if(line.has_prefix("#EXTINF"))
								continue;
							list += line;
//							data.append_url("http://media.example.com/entire.ts"); // for testing
							//stdout.printf("%s\n", line);
						}
					}
				}
			} 
			catch(GLib.Error e) {
				print("%s", e.message);
			}
			return new Data();
		}

		public override async Data? read_asyn(File _file) throws ReaderError {
//			Data data = new Data();
			this.file = _file;
			return null;
		}
	}
}

