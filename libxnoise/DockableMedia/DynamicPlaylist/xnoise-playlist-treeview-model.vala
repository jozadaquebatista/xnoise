using Gtk;


private class Xnoise.PlaylistStore : Gtk.TreeStore {
	private GLib.Type[] col_types = new GLib.Type[] {
		typeof(Gdk.Pixbuf),
		typeof(string)
	};
	
	construct {
		this.set_column_types(col_types);
		this.populate();
	}

	private void populate() {
		TreeIter iter;
		Gdk.Pixbuf pixb = null;
		Gtk.Invisible i = new Gtk.Invisible();
		try {
			if(IconTheme.get_default().has_icon("xn-playlist"))
				pixb = IconTheme.get_default().load_icon("xn-playlist", 16, IconLookupFlags.FORCE_SIZE);
			else
				pixb = i.render_icon_pixbuf(Gtk.Stock.YES, IconSize.BUTTON);
		}
		catch(Error e) {
		}
		this.append(out iter, null);
		this.set(iter, 0, pixb, 1 , _("Most popular"));
		this.append(out iter, null);
		this.set(iter, 0, pixb, 1 , _("Recently added"));
	}
}
