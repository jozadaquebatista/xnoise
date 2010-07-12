/* pl-asx-file-writer.vala
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
 * 	Jörn Magens <shuerhaaken@googlemail.com>
 * 	Francisco Pérez Cuadrado <fsistemas@gmail.com>
 */

namespace Pl {
	private class Asx.FileWriter : AbstractFileWriter {
		
		private Data[] data_collection;
		private File file;

		public override Result write(File _file, Data[] _data_collection) throws Internal.WriterError {
			this.file = _file;
			this.data_collection = _data_collection;
			if(data_collection != null && data_collection.length > 0) {
				try {
					if(file.query_exists(null)) {
						file.delete(null);
					}

					var file_stream = file.create(FileCreateFlags.NONE, null);
					var data_stream = new DataOutputStream(file_stream);
					
					data_stream.put_string("<asx version=\"3.0\">\n", null);
					data_stream.put_string("\t<title></title>\n", null); //TODO: Playlist title
					foreach(Data d in data_collection) {
						if(d.get_field(Data.Field.URI) == null)
							continue;
						data_stream.put_string("\t<entry>\n", null);
						data_stream.put_string("\t <ref href=\"" + d.get_field(Data.Field.URI) + "\" />\n", null);
						data_stream.put_string("\t</entry>\n\n", null);
					}
					data_stream.put_string("</asx>\n", null);
				} 
				catch(GLib.Error e) {
					print("%s\n", e.message);
				}
			}
			return Result.SUCCESS;
		}
		
		public override async Result write_asyn(File _file, Data[] _data_collection) throws Internal.WriterError {
			this.file = _file;
			this.data_collection = _data_collection;
			return Result.UNHANDLED;
		}
	}
}

