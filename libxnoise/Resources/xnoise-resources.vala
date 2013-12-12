/* xnoise-recources.vala
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
 *     Jörn Magens
 */




namespace Xnoise.Resources {
    
    public static const string UNKNOWN_ARTIST           = "unknown artist";
    public static const string VARIOUS_ARTISTS          = "Various artists";
    public static const string UNKNOWN_TITLE            = "unknown title";
    public static const string UNKNOWN_ALBUM            = "unknown album";
    public static const string UNKNOWN_GENRE            = "unknown genre";
    public static const string UNKNOWN_ORGANIZATION     = "unknown organization";
    public static const string UNKNOWN_LOCATION         = "unknown location";
    public static const string EMPTYSTRING              = "";
    
    public static const string VA_ICON_SYMBOLIC         = "system-users-symbolic";
    public static const string ARTIST_ICON_SYMBOLIC     = "avatar-default-symbolic";
    public static const string ALBUM_ICON_SYMBOLIC      = "media-optical-symbolic";
    public static const string TITLE_ICON_SYMBOLIC      = "audio-x-generic-symbolic";
    public static const string GENRE_ICON_SYMBOLIC      = "emblem-documents-symbolic";
    public static const string VIDEO_ICON_SYMBOLIC      = "video-x-generic-symbolic";
    public static const string STREAM_ICON_SYMBOLIC     = "network-cellular-signal-excellent-symbolic";
    
    public static const string MAIN_DATABASE_NAME       = "db.sqlite";
    public static const string INIFILE                  = "xnoise.ini";
    
    public static const string VIDEOVIEW_NAME           = "VideoView"; 
    public static const string TRACKLIST_VIEW_NAME      = "TrackListView";
    public static const string LYRICS_VIEW_NAME         = "LyricsView";  

    internal static const int ICON_LARGE_PIXELSIZE      = 180;
    internal static const int ICON_SMALL_PIXELSIZE      = 30;
    
    public static const int VIDEOTHUMBNAILSIZE   = 40; //TODO
    internal static const int DB_VERSION_MAJOR   = 21;
    internal static const int DB_VERSION_MINOR   = 0;

    public static const string UNKNOWN_ARTIST_LOCALIZED = _("unknown artist");
    public static const string UNKNOWN_TITLE_LOCALIZED  = _("unknown title");
    public static const string UNKNOWN_ALBUM_LOCALIZED  = _("unknown album");
    
    internal static const string SHOWVIDEO              = _("Now Playing");
    internal static const string SHOWTRACKLIST          = _("Tracklist");
    internal static const string SHOWLYRICS             = _("Lyrics");
    internal static const string HIDE_LIBRARY           = _("Hide Media Library");
    internal static const string SHOW_LIBRARY           = _("Show Media Library");

    internal static const string AUTHORS[] = {
        "Jörn Magens",
        "Andi",
        "Francisco Pérez Cuadrado",
        "Tal",
        "Dominique Lasserre",
        null
    };
    internal static const string COPYRIGHT       = "Copyright \xc2\xa9 2008-2013 Jörn Magens";
    internal static const string PROGRAM_NAME    = "xnoise";
    internal static const string WEBSITE         = "http://www.xnoise-media-player.com/";
    internal static const string WEB_FAQ         = "https://bitbucket.org/shuerhaaken/xnoise/wiki/FAQ";
    internal static const string WEB_KEYBOARD_SC = "https://bitbucket.org/shuerhaaken/xnoise/wiki/KeyBindings";
}
