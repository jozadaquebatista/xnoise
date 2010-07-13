/* pl-pls-file-reader.vala
 *
 * Copyright (C) 2010  Jörn Magens
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

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
	private class Pls.FileReader : AbstractFileReader {
		private unowned File file;
		
		public override Data[] read(File _file) throws InternalReaderError {
			Data[] data_collection = {};
			this.file = _file;
			set_base_path();
			if(!file.query_exists(null)) { 
				stderr.printf ("File '%s' doesn't exist.\n", file.get_uri());
				return data_collection;
			}

			try {
				var in_stream = new DataInputStream (file.read (null));
				string line;
				int numberofentries = 0;

				//Read header => [playlist]
				if( (line = in_stream.read_line (null, null)) != null ) {
					if ( !line.has_prefix( "[playlist]" ) ) {
						return data_collection;
					}
					Data d = null;
					while ((line = in_stream.read_line (null, null)) != null) {
						
						//Ignore blank line
						if( line.size() == 0 ) { 
							continue; 
						}

						if(line.down().contains("numberofentries")) {
							var arrayNumberOfEntries = line.split("=");

							if(arrayNumberOfEntries.length == 2) {
								numberofentries = arrayNumberOfEntries[1].to_int();
								//print("There are %d entries: \n", numberofentries);
							}
							continue;
						}
						if(line.has_prefix("File")) {
							//TODO: handle title and length for current entry
							d = new Data();
							string file_line = line;
							//string title_line = in_stream.read_line (null, null);
							//string length_line = in_stream.read_line (null, null);
							if(file_line != null) {
								var arrayFile = file_line.split("=");
								if(arrayFile != null && arrayFile.length >= 2) {
									File tmp = get_file_for_location(ref arrayFile[1], ref base_path);
									d.add_field(Data.Field.URI, tmp.get_uri());
								}
							}
							data_collection += d;
						}
					}
				}
			} 
			catch (GLib.Error e) {
				print("Error: %s\n", e.message);
				error ("%s", e.message);
			}
			return data_collection;
		}

		public override async Data[] read_asyn(File _file) throws InternalReaderError {
			Data[] data_collection = {};
			this.file = _file;
			set_base_path();
			return data_collection;
		}

		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}

