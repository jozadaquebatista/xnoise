/* vlfm-util.vala
 *
 * Copyright (C) 2011  Francisco Pérez Cuadrado
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 * 	Francisco Perez C.
 */

namespace Lastfm {
	public class Util {

		private static string md5(string str) {
			string hexmd5;
			Checksum ch = new Checksum(ChecksumType.MD5);
			ch.update((uchar[])str.to_utf8(), -1);
			hexmd5 = ch.get_string();
			return hexmd5;
		}

		//Generate API_SIG from URI paramaters
		public static string get_api_sig_url(string param, string apiSecret) {
			string result = "";
			var arrayParams = param.split("&");
			for(int i = 0; i < arrayParams.length; i++) {
				var nameValue = arrayParams[i].split("=");
				var name = nameValue[0];
				var val = nameValue[1];
				result += (name + val);
			}
			result += apiSecret;
			string aaa = result;
			result = md5(result);
			print("API_SIG: from %s == %s\n", aaa, result);
			return result;
		}
	}
}
