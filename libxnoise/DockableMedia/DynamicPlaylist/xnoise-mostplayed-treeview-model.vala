/* xnoise-mostplayed-treeview-model.vala
 *
 * Copyright (C) 2012  Jörn Magens
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


using Gtk;


private class Xnoise.MostplayedTreeviewModel : Gtk.ListStore {
	
	private GLib.Type[] col_types = new GLib.Type[] {
		typeof(Gdk.Pixbuf), //ICON
		typeof(string),     //VIS_TEXT
		typeof(Xnoise.Item?)//ITEM
	};
	
	public enum Column {
		ICON = 0,
		VIS_TEXT,
		ITEM,
		N_COLUMNS
	}

	construct {
		this.set_column_types(col_types);
		this.populate();
	}

	private void populate() {
		
		Worker.Job job;
		job = new Worker.Job(Worker.ExecutionType.ONCE, insert_most_played_job);
		db_worker.push_job(job);
	}
	
	private bool insert_most_played_job(Worker.Job job) {
		string searchtext = "";
		job.items = db_browser.get_most_played(ref searchtext);
		Idle.add( () => {
			TreeIter iter;
			foreach(Item? i in job.items) {
				this.append(out iter);
				this.set(iter,
				         Column.VIS_TEXT, i.text,
				         Column.ITEM, i
				);
			}
			return false;
		});
		return false;
	}
}
