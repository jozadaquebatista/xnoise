/* vlfm-util.vala
 *
 * Copyright (C) 2011  Francisco Pérez Cuadrado
 * Copyright (C) 2011-2012  Jörn Magens
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
 * 	JM <shuerhaaken@googlemail.com>
 */

using Xnoise;
using Xnoise.Services;


namespace Lastfm {
	
	private enum UrlParamType {
		ARTIST = 0,
		ALBUM,
		TITLE,
		TRACKNUMBER,
		DURATION,
		METHOD,
		TIMESTAMP,
		API_KEY,
		SESSION_KEY,
		SECRET,
		USERNAME,
		LANGUAGE,
		AUTOCORRECT,
		MAX
	}
	
	private class UrlBuilder : GLib.Object {
		// class to build lastfm url with signatures from parameters
		private HashTable<UrlParamType, Value?> values = new HashTable<UrlParamType, Value?>(direct_hash, direct_equal);
		private UrlParamType[] pta = new UrlParamType[0];
		
		public void add_param(UrlParamType pt, Value? par) {
			if((int)pt < 0 || (int)pt >= UrlParamType.MAX) {
				print("ignoring invalid param\n");
				return;
			}
			if(par == null) {
				print("ignoring invalid param\n");
				return;
			}
			if(paramtype_used(pt)) {
				print("lastfm param was already used. abort\n");
				return;
			}
			// save Value
			values.insert(pt, par);
			// save order
			pta += pt;
		}
		
		private bool paramtype_used(UrlParamType pt) {
			foreach(UrlParamType p in pta) {
				if(p == pt)
					return true;
			}
			return false;
		}
		
		public string? get_url(string url_root, bool use_signature = false) {
			string? signature = null;
			if(use_signature) {
				signature = build_signature();
				if(signature == null) {
					print("invalid signature generation\n");
					return null;
				}
			}
			return build_url(url_root, signature);
		}
		
		private void add_seperator(ref bool first, ref StringBuilder sb) {
			if(first) {
				sb.append("?");
				first = false;
			}
			else {
				sb.append("&");
			}
		}
		
		private string? build_url(string url_root, string? signature) {
			StringBuilder sb = new StringBuilder(url_root);
			string? strbuffer = null;
			bool first = true;
			foreach(UrlParamType p in pta) {
				Value? v = values.lookup(p);
				if(v == null)
					return null;
				
				switch(p) {
					case UrlParamType.ARTIST: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param artist.\n");
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("artist=");
						sb.append(WebAccess.escape(strbuffer));
						break;
					}
					case UrlParamType.AUTOCORRECT: {
						int ac = (int)v;
						if(ac < 0 || ac > 1) {
							print("invalid lastfm param autocorrect.\n");
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("autocorrect=");
						sb.append("%d".printf(ac));
						break;
					}
					case UrlParamType.USERNAME: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param username.\n");
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("username=");
						sb.append(WebAccess.escape(strbuffer));
						break;
					}
					case UrlParamType.LANGUAGE: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param language.\n");
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("lang=");
						sb.append(WebAccess.escape(strbuffer));
						break;
					}
					case UrlParamType.ALBUM: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param album.\n");
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("album=");
						sb.append(WebAccess.escape(strbuffer));
						break;
					}
					case UrlParamType.TITLE: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param track.\n");
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("track=");
						sb.append(WebAccess.escape(strbuffer));
						break;
					}
					case UrlParamType.METHOD: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param method.\n");
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("method=");
						sb.append(strbuffer);
						break;
					}
					case UrlParamType.API_KEY: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param api_key.\n");
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("api_key=");
						sb.append(strbuffer);
						break;
					}
					case UrlParamType.SECRET: {
						break;
					}
					case UrlParamType.SESSION_KEY: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param session_key.\n");
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("sk=");
						sb.append(strbuffer);
						break;
					}
					case UrlParamType.TRACKNUMBER: {
						uint tn = (uint)v;
						if(tn == 0) {
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("trackNumber=");
						sb.append("%u".printf(tn));
						break;
					}
					case UrlParamType.DURATION: {
						uint du = (uint)v;
						if(du == 0) {
							continue;
						}
						add_seperator(ref first, ref sb);
						sb.append("duration=");
						sb.append("%u".printf(du));
						break;
					}
					case UrlParamType.TIMESTAMP: {
						int64 ti = (int64)v;
						add_seperator(ref first, ref sb);
						sb.append("timestamp=");
						sb.append("%lld".printf(ti));
						break;
					}
					default: break;
				}
				strbuffer = null;
			}
			if(signature != null) {
				sb.append("&api_sig=");
				sb.append(signature);
			}
			return (owned)sb.str;
		}
		
		private string? build_signature() {
			StringBuilder sb = new StringBuilder();
			string? strbuffer = null;
			string? secret = null;
			
			foreach(UrlParamType p in pta) {
				Value? v = values.lookup(p);
				if(v == null) {
					print("Could not get lastfm param\n");
					return null;
				}
				
				switch(p) {
					case UrlParamType.ARTIST: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param artist.\n");
							continue;
						}
						sb.append("artist");
						sb.append(strbuffer);
						break;
					}
					case UrlParamType.ALBUM: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param album.\n");
							continue;
						}
						sb.append("album");
						sb.append(strbuffer);
						break;
					}
					case UrlParamType.TITLE: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param track.\n");
							continue;
						}
						sb.append("track");
						sb.append(strbuffer);
						break;
					}
					case UrlParamType.METHOD: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param method.\n");
							continue;
						}
						sb.append("method");
						sb.append(strbuffer);
						break;
					}
					case UrlParamType.API_KEY: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param api_key.\n");
							continue;
						}
						sb.append("api_key");
						sb.append(strbuffer);
						break;
					}
					case UrlParamType.SECRET: {
						secret = (string)v;
						if(secret == null) {
							print("invalid lastfm param secret.\n");
							continue;
						}
						break;
					}
					case UrlParamType.SESSION_KEY: {
						strbuffer = (string)v;
						if(strbuffer == null) {
							print("invalid lastfm param session_key.\n");
							continue;
						}
						sb.append("sk");
						sb.append(strbuffer);
						break;
					}
					case UrlParamType.TRACKNUMBER: {
						uint tn = (uint)v;
						if(tn == 0) {
							continue;
						}
						sb.append("trackNumber");
						sb.append("%u".printf(tn));
						break;
					}
					case UrlParamType.DURATION: {
						uint du = (uint)v;
						if(du == 0) {
							continue;
						}
						sb.append("duration");
						sb.append("%u".printf(du));
						break;
					}
					case UrlParamType.TIMESTAMP: {
						int64 ti = (int64)v;
						sb.append("timestamp");
						sb.append("%lld".printf(ti));
						break;
					}
					default: break;
				}
				strbuffer = null;
			}
			if(secret == null) {
				print("no secret given\n");
				return null;
			}
			sb.append(secret);
			//print("string for signature: %s\n", sb.str);
			return Checksum.compute_for_string(ChecksumType.MD5, sb.str);
		}
	}
	
	public class Util : GLib.Object {
		//Generate API_SIG from URI paramaters
		public static string get_api_sig_url(string param, string apiSecret) {
			string result = EMPTYSTRING;
			var arrayParams = param.split("&");
			for(int i = 0; i < arrayParams.length; i++) {
				var nameValue = arrayParams[i].split("=");
				var name = nameValue[0];
				var val = nameValue[1];
				result += (name + val);
			}
			result += apiSecret;
			string aaa = result;
			result = Checksum.compute_for_string(ChecksumType.MD5, result);
			print("API_SIG: from %s == %s\n", aaa, result);
			return (owned)result;
		}
	}
}
