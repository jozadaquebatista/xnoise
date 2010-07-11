/* pl-xspf-file-writer.vala
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
	// base class for all playlist filewriter implementations
	private class Xspf.FileWriter : AbstractFileWriter {
	
		private Data data;
		private File file;

		public override Result write(File _file, Data _data) throws WriterError {
			this.file = _file;
			this.data = _data;
			if(data != null) {
				var list = data.urls;
				if(list != null && list.length > 0) {
					try {
						if(file.query_exists(null)) {
							file.delete(null);
						}

						var file_stream = file.create(FileCreateFlags.NONE, null);
						var data_stream = new DataOutputStream(file_stream);
						
						data_stream.put_string("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n", null);
						data_stream.put_string("<playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\">\n", null);
						data_stream.put_string("  <trackList>\n", null);
						for(int i=0;i<list.length;i++) {
							data_stream.put_string("    <track>\n", null);
							data_stream.put_string("      <title></title>\n", null);
							data_stream.put_string("      <location>" + list[i]  + "\n", null);
							data_stream.put_string("    </track>\n", null);
						}
						data_stream.put_string("  </trackList>\n", null);
						data_stream.put_string("</playlist>\n", null);
					} catch(GLib.Error e) {
						print("%s\n", e.message);
					}
				}
			}
			return Result.UNHANDLED;
		}
		
		public override async Result write_asyn(File _file, Data _data) throws WriterError {
			this.file = _file;
			this.data = _data;
			return Result.UNHANDLED;
		}
	}
}

