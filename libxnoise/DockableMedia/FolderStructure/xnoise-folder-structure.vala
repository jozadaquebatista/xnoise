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
using Gdk;

using Xnoise;
using Xnoise.Resources;


private class Xnoise.FolderStructure : TreeView, IParams, TreeQueryable {
	private bool _use_treelines = false;
	private bool dragging = false;
	private ListFlowingTextRenderer renderer = null;
	private Gtk.Menu menu;
	public FolderStructureModel folder_structure_model;
	
	public bool use_treelines {
		get {
			return _use_treelines;
		}
		set {
			_use_treelines = value;
			this.enable_tree_lines = value;
		}
	}
	
    private const TargetEntry[] src_target_entries = {
        {"application/custom_dnd_data", TargetFlags.SAME_APP, 0}
    };

    // targets used with this as a destination
    private const TargetEntry[] dest_target_entries = {
        {"text/uri-list", TargetFlags.OTHER_APP, 0}
    };// This is not a very long list but uris are so universal
    
    //parent container of this widget (most likely scrolled window)
    private unowned Widget ow;
    private unowned DockableMedia dock;
    
    public FolderStructure(DockableMedia dock, Widget ow) {
    	this.ow = ow;
    	this.dock = dock;
    	Params.iparams_register(this);
    	folder_structure_model = new FolderStructureModel(dock);
    	this.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
    	
    	//setup_view();
    	//Idle.add(this.populate_model);
    	this.get_selection().set_mode(SelectionMode.MULTIPLE);
    	
        Gtk.drag_source_set(this,
		                    Gdk.ModifierType.BUTTON1_MASK,
		                    src_target_entries,
		                    Gdk.DragAction.COPY
		                    );

        Gtk.drag_dest_set(this,
                          Gtk.DestDefaults.ALL,
                          dest_target_entries,
                          Gdk.DragAction.COPY
                          );
        
        //Signals
        //TODO: connect signals and do stuff
	}
	
	    // IParams functions
    public void read_params_data() {
        if(Params.get_int_value("use_treelines") == 1)
            use_treelines = true;
        else
            use_treelines = false;
    }

    public void write_params_data() {
        if(this.use_treelines)
            Params.set_int_value("use_treelines", 1);
        else
            Params.set_int_value("use_treelines", 0);
    }
    // end IParams functions
    
    
    public int get_model_item_column() {
        //TODO: fix
        return 0;
    }
    
    public TreeModel? get_queryable_model() {
        TreeModel? tm = this.get_model();
        return tm;
    }
    
    public GLib.List<TreePath>? query_selection() {
        return this.get_selection().get_selected_rows(null);
    }
}
	
	
	
	
	