/* xnoise-handler-edit-tags.vala
 *
 * Copyright (C) 2011 - 2012 Jörn Magens
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
 *     Jörn Magens
 */

using Gtk;

internal class Xnoise.HandlerEditTags : ItemHandler {
    private Action edit_title_tracklist;
    private static const string tltitleinfo = _("Edit data for track");
    private static const string tltitlename = "HandlerEditTagsActionTitleTL";

    private Action edit_title_mediabrowser;
    private static const string titleinfo = _("Edit data for track");
    private static const string titlename = "HandlerEditTagsActionTitle";
    
    private Action edit_album_mediabrowser;
    private static const string albuminfo = _("Change album data");
    private static const string albumname = "HandlerEditTagsActionAlbum";
    
    private Action edit_artist_mediabrowser;
    private static const string artistinfo = _("Change artist data");
    private static const string artistname = "HandlerEditTagsActionArtist";
    
    private Action edit_genre_mediabrowser;
    private static const string genreinfo = _("Change genre name");
    private static const string genrename = "HandlerEditTagsActionGenre";

    private static const string name = "HandlerEditTags";
    
    
    public HandlerEditTags() {
        
        edit_title_mediabrowser = new Action(); 
        edit_title_mediabrowser.action = on_edit_title_mediabrowser;
        edit_title_mediabrowser.info = titleinfo;
        edit_title_mediabrowser.name = titlename;
        edit_title_mediabrowser.stock_item = Gtk.Stock.EDIT;
        edit_title_mediabrowser.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;

        edit_album_mediabrowser = new Action(); 
        edit_album_mediabrowser.action = on_edit_album_mediabrowser;
        edit_album_mediabrowser.info = albuminfo;
        edit_album_mediabrowser.name = albumname;
        edit_album_mediabrowser.stock_item = Gtk.Stock.EDIT;
        edit_album_mediabrowser.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;

        edit_genre_mediabrowser = new Action(); 
        edit_genre_mediabrowser.action = on_edit_genre_mediabrowser;
        edit_genre_mediabrowser.info = genreinfo;
        edit_genre_mediabrowser.name = genrename;
        edit_genre_mediabrowser.stock_item = Gtk.Stock.EDIT;
        edit_genre_mediabrowser.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;

        edit_artist_mediabrowser = new Action(); 
        edit_artist_mediabrowser.action = on_edit_artist_mediabrowser;
        edit_artist_mediabrowser.info = artistinfo;
        edit_artist_mediabrowser.name = artistname;
        edit_artist_mediabrowser.stock_item = Gtk.Stock.EDIT;
        edit_artist_mediabrowser.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;

        edit_title_tracklist = new Action(); 
        edit_title_tracklist.action = on_edit_title_tracklist;
        edit_title_tracklist.info = tltitleinfo;
        edit_title_tracklist.name = tltitlename;
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
        if(global.media_import_in_progress || global.in_tag_rename)
            return null;
        if(selection != ItemSelectionType.SINGLE)
            return null;
        if(context == ActionContext.QUERYABLE_TREE_MENU_QUERY ||
           context == ActionContext.QUERYABLE_PLAYLIST_MENU_QUERY) {
            switch(type) {
                case ItemType.COLLECTION_CONTAINER_GENRE:
                    return edit_genre_mediabrowser;
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

    private void on_edit_title_mediabrowser(Item item, GLib.Value? data, GLib.Value? data2) {
        if(item.type == ItemType.LOCAL_AUDIO_TRACK)
            this.open_tagtitle_changer(item);
    }

    private void on_edit_album_mediabrowser(Item item, GLib.Value? data, GLib.Value? data2) {
        Item? i = null;
        if(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM) {
            if(data2 != null) {
                Item? it = (Item)data2;
                if(it.type != ItemType.UNKNOWN)
                    i = it;
            }
        }
        HashTable<ItemType,Item?>? item_ht = null;
        if(i != null && i.type != ItemType.UNKNOWN) {
            item_ht = new HashTable<ItemType,Item?>(direct_hash, direct_equal);
            item_ht.insert(i.type, i);
        }
        if(item_ht != null)
            print("restrictions are avail\n");
        if(item.type == ItemType.COLLECTION_CONTAINER_ALBUM)
            open_tagalbum_changer(item, item_ht);
    }

    private void on_edit_genre_mediabrowser(Item item, GLib.Value? data, GLib.Value? data2) {
        Item? i = null;
//        if(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM) {
//            if(data2 != null) {
//                i = (Item)data2;
//            }
//        }
        HashTable<ItemType,Item?>? item_ht = null;
        if(i != null) {
            item_ht = new HashTable<ItemType,Item?>(direct_hash, direct_equal);
            item_ht.insert(i.type, i);
        }
        if(item.type == ItemType.COLLECTION_CONTAINER_GENRE)
            this.open_tag_genre_changer(item, item_ht);
    }
    
    private void on_edit_artist_mediabrowser(Item item, GLib.Value? data, GLib.Value? data2) {
        Item? i = Item(ItemType.UNKNOWN);
//        if(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM) {
            if(data2 != null) {
                i = (Item)data2;
            }
//        }
        HashTable<ItemType,Item?>? item_ht = null;
        if(i != null && i.type != ItemType.UNKNOWN) {
            item_ht = new HashTable<ItemType,Item?>(direct_hash, direct_equal);
            item_ht.insert(i.type, i);
        }
        if(item.type == ItemType.COLLECTION_CONTAINER_ARTIST)
            this.open_tagartist_changer(item, item_ht);
    }
    
    private void on_edit_title_tracklist(Item item, GLib.Value? data, GLib.Value? data2) {
        if(global.media_import_in_progress)
            return;
        if(item.type == ItemType.LOCAL_AUDIO_TRACK)
            this.open_tagtitle_changer(item); //TODO: Add routine to update in tracklist
    }

//    private Menu create_edit_artist_tag_menu() {
//        var rightmenu = new Menu();
//        var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.INFO, null);
//        menu_item.set_label(_("Change artist name"));
//        menu_item.activate.connect(this.open_tagartist_changer);
//        rightmenu.append(menu_item);
//        rightmenu.show_all();
//        return rightmenu;
//    }

//    private Menu create_edit_album_tag_menu() {
//        var rightmenu = new Menu();
//        var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.INFO, null);
//        menu_item.set_label(_("Change album name"));
//        menu_item.activate.connect(this.open_tagalbum_changer);
//        rightmenu.append(menu_item);
//        rightmenu.show_all();
//        return rightmenu;
//    }

    private TagTitleEditor tte;
    private void open_tagtitle_changer(Item item) {
        tte = new TagTitleEditor(item);
        tte.sign_finish.connect( () => {
            tte = null;
        });
    }

    private TagGenreEditor tge;
    private TagArtistEditor tae;
    private TagAlbumEditor taled;
    
    private void open_tag_genre_changer(Item item, HashTable<ItemType,Item?>? restrictions = null) {
        tge = new TagGenreEditor(item, restrictions);
        tge.sign_finish.connect( () => {
            tge = null;
        });
    }
    private void open_tagartist_changer(Item item, HashTable<ItemType,Item?>? restrictions = null) {
        tae = new TagArtistEditor(item, restrictions);
        tae.sign_finish.connect( () => {
            tae = null;
        });
    }

    private void open_tagalbum_changer(Item item, HashTable<ItemType,Item?>? restrictions = null) {
        taled = new TagAlbumEditor(item, restrictions);
        taled.sign_finish.connect( () => {
            taled = null;
        });
    }
}

