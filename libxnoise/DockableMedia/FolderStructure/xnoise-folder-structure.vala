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
    	folder_structure_model = new FolderStructureModel(dock, this);
    	this.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
    	
    	//setup_view();
    	//Idle.add(this.populate_model);
    	this.get_selection().set_mode(SelectionMode.MULTIPLE);
    	this.headers_visible = false;
    	
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
        
        var column = new TreeViewColumn();
        int hsepar = 0;
        this.style_get("horizontal-separator", out hsepar);
        var renderer = new ListFlowingTextRenderer(column, hsepar);
        column.pack_start(renderer, true);
        column.add_attribute(renderer, "itype"  , FolderStructureModel.Column.ITEMTYPE);
        column.add_attribute(renderer, "text", FolderStructureModel.Column.VIS_TEXT);
        column.add_attribute(renderer, "pix" , FolderStructureModel.Column.ICON);
        
        this.row_activated.connect(this.on_row_activated);
        
        this.insert_column(column, -1);
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
        
    public Item[] get_row_items(TreePath treePath) {
    	Item? baseItem = null;
    	TreeIter baseIter;
    	this.model.get_iter(out baseIter, treePath);
    	this.model.get(baseIter, FolderStructureModel.Column.ITEM, out baseItem);
    	Item[] items = {};
    	
    	Queue<TreeIter?> stack = new Queue<TreeIter?>();
    	stack.push_head(baseIter);
    	while(!stack.is_empty())
    	{
    		TreeIter iter = stack.pop_head();
    		TreeIter child;
	    	if(this.model.iter_children(out child, iter)) { //do we have children?
	    		do {
	    			stack.push_head(child);
	    		} while(this.model.iter_next(ref child));
	    	}
	    	else { //No children, should be a track but check to be sure
	    		Item? item = null;
	    		this.model.get(iter, FolderStructureModel.Column.ITEM, out item);
	    		//if(item.type == ItemType.LOCAL_AUDIO_TRACK) {
	    			items += item;
	    			stdout.printf("Found item %s\n", item.uri);
	    		//}
	    	}
    	}
    	return items;
    }
    
    public void on_row_activated(Gtk.Widget sender, TreePath treePath, TreeViewColumn treeColumn) {
    	print("on_row_activated\n");                
        ItemHandler? itemHandler = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
        if(itemHandler == null) {
            print("itemHandler was null\n");
            return;
        }
        Item[] items = get_row_items(treePath);
        Worker.Job job = new Worker.Job();
        job.items = items;
        unowned Action? action = itemHandler.get_action(ItemType.UNKNOWN, ActionContext.REQUESTED, ItemSelectionType.MULTIPLE);
        if(action != null)
            action.action(Item(), null, job);
        else
            print("action was null\n");
	}
}
	
	
	
	
	