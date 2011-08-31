/* xnoise-handler-edit-tags.vala
 *
 * Copyright (C) 2011  Jörn Magens
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

public class Xnoise.HandlerEditTags : ItemHandler {
	private Action edit_title_tracklist;
	private const string tltitleinfo = _("Edit metadata for track");
	private const string tltitlename = "HandlerEditTagsActionTitleTL";

	private Action edit_title_mediabrowser;
	private const string titleinfo = _("Edit metadata for track");
	private const string titlename = "HandlerEditTagsActionTitle";
	
	private Action edit_album_mediabrowser;
	private const string albuminfo = _("Change album name");
	private const string albumname = "HandlerEditTagsActionAlbum";
	
	private Action edit_artist_mediabrowser;
	private const string artistinfo = _("Change artist name");
	private const string artistname = "HandlerEditTagsActionArtist";
	
	private const string name = "HandlerEditTags";
	private unowned Main xn;
	
	
	public HandlerEditTags() {
		xn = Main.instance;
		
		edit_title_mediabrowser = new Action(); 
		edit_title_mediabrowser.action = on_edit_title_mediabrowser;
		edit_title_mediabrowser.info = this.titleinfo;
		edit_title_mediabrowser.name = this.titlename;
		edit_title_mediabrowser.stock_item = Gtk.Stock.EDIT;
		edit_title_mediabrowser.context = ActionContext.MEDIABROWSER_MENU_QUERY;

		edit_album_mediabrowser = new Action(); 
		edit_album_mediabrowser.action = on_edit_album_mediabrowser;
		edit_album_mediabrowser.info = this.albuminfo;
		edit_album_mediabrowser.name = this.albumname;
		edit_album_mediabrowser.stock_item = Gtk.Stock.EDIT;
		edit_album_mediabrowser.context = ActionContext.MEDIABROWSER_MENU_QUERY;

		edit_artist_mediabrowser = new Action(); 
		edit_artist_mediabrowser.action = on_edit_artist_mediabrowser;
		edit_artist_mediabrowser.info = this.artistinfo;
		edit_artist_mediabrowser.name = this.artistname;
		edit_artist_mediabrowser.stock_item = Gtk.Stock.EDIT;
		edit_artist_mediabrowser.context = ActionContext.MEDIABROWSER_MENU_QUERY;

		edit_title_tracklist = new Action(); 
		edit_title_tracklist.action = on_edit_title_tracklist;
		edit_title_tracklist.info = this.tltitleinfo;
		edit_title_tracklist.name = this.tltitlename;
		edit_title_tracklist.stock_item = Gtk.Stock.EDIT;
		edit_title_tracklist.context = ActionContext.TRACKLIST_MENU_QUERY;

		//print("constructed %s\n", this.name);
	}

	public override ItemHandlerType handler_type() {
		return ItemHandlerType.TAG_EDITOR;
	}
	
	public override unowned string handler_name() {
		return name;
	}

	public override unowned Action? get_action(ItemType type, ActionContext context, ItemSelectionType selection) {
		if(selection != ItemSelectionType.SINGLE)
			return null;
		if(context == ActionContext.MEDIABROWSER_MENU_QUERY) {
			switch(type) {
				case ItemType.COLLECTION_CONTAINER_ARTIST:
					return edit_artist_mediabrowser;
				case ItemType.COLLECTION_CONTAINER_ALBUM:
					return edit_album_mediabrowser;
				case ItemType.LOCAL_AUDIO_TRACK:
					return edit_title_mediabrowser;
				default:
					break;
			}
		}
		if(context == ActionContext.TRACKLIST_MENU_QUERY) {
			switch(type) {
				case ItemType.LOCAL_AUDIO_TRACK:
					return edit_title_tracklist;
				default:
					break;
			}
		}
		return null;
	}

	private void on_edit_title_mediabrowser(Item item, GLib.Value? data) {
		if(item.type == ItemType.LOCAL_AUDIO_TRACK)
			this.open_tagtitle_changer(item);
	}

	private void on_edit_album_mediabrowser(Item item, GLib.Value? data) {
		if(item.type == ItemType.COLLECTION_CONTAINER_ALBUM)
			this.open_tagalbum_changer(item);
	}

	private void on_edit_artist_mediabrowser(Item item, GLib.Value? data) {
		if(item.type == ItemType.COLLECTION_CONTAINER_ARTIST)
			this.open_tagartist_changer(item);
	}
	
	private void on_edit_title_tracklist(Item item, GLib.Value? data) {
		if(item.type == ItemType.LOCAL_AUDIO_TRACK)
			this.open_tagtitle_changer(item); //TODO: Add routine to update in tracklist
	}

//	private Menu create_edit_artist_tag_menu() {
//		var rightmenu = new Menu();
//		var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.INFO, null);
//		menu_item.set_label(_("Change artist name"));
//		menu_item.activate.connect(this.open_tagartist_changer);
//		rightmenu.append(menu_item);
//		rightmenu.show_all();
//		return rightmenu;
//	}

//	private Menu create_edit_album_tag_menu() {
//		var rightmenu = new Menu();
//		var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.INFO, null);
//		menu_item.set_label(_("Change album name"));
//		menu_item.activate.connect(this.open_tagalbum_changer);
//		rightmenu.append(menu_item);
//		rightmenu.show_all();
//		return rightmenu;
//	}

	private TagTitleEditor tte;
	private void open_tagtitle_changer(Item item) {
		tte = new TagTitleEditor(item);
		tte.sign_finish.connect( () => {
			tte = null;
		});
	}

	private TagArtistAlbumEditor tae;
	
	private void open_tagartist_changer(Item item) {
		tae = new TagArtistAlbumEditor(item);
		tae.sign_finish.connect( () => {
			tae = null;
		});
	}

	private void open_tagalbum_changer(Item item) {
		tae = new TagArtistAlbumEditor(item);
		tae.sign_finish.connect( () => {
			tae = null;
		});
	}
}

