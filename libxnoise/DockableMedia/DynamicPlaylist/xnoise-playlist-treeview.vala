using Gtk;

private class Xnoise.PlaylistTreeView : Gtk.TreeView {
	private unowned MainWindow win;
	
	public PlaylistTreeView(MainWindow window) {
		this.win = window; // use this ref because static main_window
		                   //is not yet set up at construction time
		this.headers_visible = false;
		this.get_selection().set_mode(SelectionMode.MULTIPLE);
		PlaylistStore mod = new PlaylistStore();
		var column = new TreeViewColumn();
		var renderer = new CellRendererText();
		var rendererPb = new CellRendererPixbuf();
		column.pack_start(rendererPb, false);
		column.pack_start(renderer, true);
		column.add_attribute(rendererPb, "pixbuf", 0);
		column.add_attribute(renderer, "text", 1);
		this.insert_column(column, -1);
		this.model = mod;
	}
}

