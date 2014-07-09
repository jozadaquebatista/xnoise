/* xnoise-folder-structure.vala
 *
 * Copyright (C) 2014  Marius Gräfe
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
 *     Marius Gräfe
 */
 
 using Gtk;
 using Xnoise;
 using Xnoise.Utilities;
 
 private class Xnoise.FolderStructureModel : Gtk.TreeStore, Gtk.TreeModel {
 	private unowned DockableMedia dock;
 	private FolderStructure view;
	public bool populating_model { get; private set; default = false; }
	
 	public enum Column {
 		ICON = 0,
 		VIS_TEXT,
 		ITEM,
 		ITEMTYPE,
 		N_COLUMNS
 	}
 	
 	private GLib.Type[] col_types = new GLib.Type[] {
 		typeof(Gdk.Pixbuf), 	//ICON
 		typeof(string), 		//VIS_TEXT
 		typeof(Xnoise.Item?), 	//ITEM
 		typeof(ItemType) 		//LEVEL
 	};
 	
 	public FolderStructureModel(DockableMedia dock, FolderStructure view) {
 		this.dock = dock;
 		this.view = view;
 		set_column_types(col_types);
 		
 		//TODO: connect signals
 		populate_model();
 	}
 	
 	private bool populate_model() {
		if(populating_model)
			return false;
		populating_model = true;
		
		TreeIter test_iter0;
		this.append(out test_iter0, null);
		this.set(test_iter0, 
			Column.ICON, null,
			Column.VIS_TEXT, "test text",
			Column.ITEM, null,
			Column.ITEMTYPE, ItemType.LOCAL_FOLDER);
		
		TreeIter test_iter1;
		this.append(out test_iter1, test_iter0);
		this.set(test_iter1,
			Column.ICON, null,
			Column.VIS_TEXT, "test text2",
			Column.ITEM, null,
			Column.ITEMTYPE, ItemType.LOCAL_FOLDER);
		
		foreach(Item? item in media_importer.get_media_folder_list()) {
            if(item == null || item.uri == null) {
                continue;
            }
            File f = File.new_for_uri(item.uri);
            //if(GlobalAccess.main_cancellable.is_cancelled()) {
            //    return;
            //}
            
            add_folder_recursive(f, null);
            //var job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job, Worker.Priority.HIGH);
            //job.set_arg("media_folder", f.get_path());
            //job.item = item;
            //this.worker.push_job(job);
        }
		
		view.model = this;
        populating_model = false;
		return true;
 	}
 	
    private const string attr = FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE;
 	
 	private bool suffix_supported(string suffix)
 	{
 		//TODO: we need a better way to do this
 		return suffix == "mp3" || suffix == "mp4" || suffix == "wav";
 	}
 	
 	private void add_file(File file, TreeIter? parentIter)
 	{
 		Item item = new Item(ItemType.LOCAL_AUDIO_TRACK, file.get_uri());
 		TreeIter iter;
 		this.append(out iter, parentIter);
 		this.set(iter,  
 			Column.ICON, null,
			Column.VIS_TEXT, file.get_basename(),
			Column.ITEM, item,
			Column.ITEMTYPE, item.type);
 	}
 	
 	private TreeIter add_folder(File file, TreeIter? parentIter)
 	{
        TreeIter iter;
        this.append(out iter, parentIter);
        this.set(iter, 
        		Column.ICON, null,
				Column.VIS_TEXT, file.get_basename(),
				Column.ITEM, null,
				Column.ITEMTYPE, ItemType.LOCAL_FOLDER);
		return iter;
 	}
 	
 	private bool add_folder_recursive(File dir, TreeIter? parentIter)
 	{
 		FileEnumerator enumerator;
        try {
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            print("Error importing directory %s. %s\n", dir.get_path(), e.message);
            return false;
        }
        bool found_playable_files = false;
        GLib.FileInfo info;
        while((info = enumerator.next_file()) != null) {
            string filename = info.get_name();
            string filepath = Path.build_filename(dir.get_path(), filename);
            File file = File.new_for_path(filepath);
            FileType filetype = info.get_file_type();
            if(filename.has_prefix("."))
                continue;
            if(filetype == FileType.DIRECTORY) {
				TreeIter iter = add_folder(file, parentIter);
				if(add_folder_recursive(file, iter))
					found_playable_files = true;
				else
					this.remove(ref iter);
            } else {
          		string uri_lc = filename.down();
                string suffix = get_suffix_from_filename(uri_lc);
                if(suffix_supported(suffix))
                {
                	add_file(file, parentIter);
                	found_playable_files = true;
                }
            }
        }
        return found_playable_files;
 	}
}






