/* xnoise-testplugin.vala
 *
 * Copyright (C) 2009  Jörn Magens
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
 * 	Jörn Magens
 */
 
using Xnoise;
using Gtk;

public class TestPlugin : Plugin, IPlugin {
	public TestPlugin(string name, string? title) {
		base(name, title);
	}

	private Main xn;
	private string tabname = "<b>Test</b>";

//BEGIN REGION IPlugin
	public void activate(ref weak Main xn) {
		this.xn = xn;
		print("\nloading plugin \"Test\"....\n");
		Label tablabel = new Label(tabname);
		tablabel.use_markup = true;
		tablabel.angle = 90;
		xn.main_window.browsernotebook.append_page(new Label("Test"), tablabel);
	}

	public string pname { construct set; get; }
//END REGION IPlugin

}

