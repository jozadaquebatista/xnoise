**XNOISE** is a **media player** for Gtk+ with a slick GUI, great speed and lots of features.

Unlike Rhythmbox, Banshee or itunes, Xnoise uses a **tracklist centric design**. The tracklist is a list of video or music tracks that are played one by one without being removed (right side of window).
This gives you the possibility to queue any track in any order, regardless if they are on the same album. Tracks or groups of tracks can be reordered at any time via drag and drop.

The **media browser (left side of the window) contains all available media** as a **hierarchical tree structure of the available metadata**. 
It is easy to find a single track, artist or album by using this tree structure or by just entering a search term. 
From the media browser, single or multiple tracks, streams, albums, artists or videos can be dragged into the tracklist to every position.

![Image of tracklist view](https://lh6.googleusercontent.com/-1evYUORPU54/Ti_GNiHI91I/AAAAAAAAATM/lZhT5S-biQc/scrot20110727_03.png)

   _..the tracklist view of xnoise (visible columns can be selected from the context menu)_


Xnoise can play **every kind of audio/video data that gstreamer can handle**. 


***

**PLEASE HELP IMPROVING XNOISE!**
If people would take over some tasks, fix some bugs or help developing, then the development of xnoise could be much faster.
    - Xnoise could need some help packaging for other distros. 
    - You can translate xnoise into your language. 
    - If you feel like you should add a feature to xnoise or a plugin then you should write to the mailing list.
***

Xnoise is designed to always restore it's last state on the next run (window position, window size, content of the tracklist, activated plugins, ...)

Within a playing track, it's possible to *jump to any position* by clicking the position bar or by scrolling on it.
Metadata of tracks can be edited and by that the appeatance of the tracks in xnoise's mediabrowser can be improved.

There are **plugins available.** By now there are, e.g. a plugin that shows notifications, a mpris v1/v2 dbus interfaces, ayatana soundmenu plugin for ubuntu, lastfm scrobbling and album image fetching ... 


'Now playing' information using album image and track information:

![Image of album image fetching](https://lh6.googleusercontent.com/-BUyjT939BW4/Ti_CEnl4E1I/AAAAAAAAASY/Xr5eE5K2z3M/scrot20110727.png)

  _Automatic album image fetching_


Video support:

![Image video](https://lh6.googleusercontent.com/-Jpx2cesWgVM/TgIp9kH5E8I/AAAAAAAAARg/9FWslkuEOXA/xnoise_scrot_20110622_2.png)

  _xnoise in compact mode and showing a video_


Lyrics fetching:

![Image lyrics](https://lh4.googleusercontent.com/-bmeFpCmHm2E/Ti_DVk5mAbI/AAAAAAAAASo/2UA6r1vQLEM/scrot20110727_02.png)

  _song lyrics are fetched automatically from various web sources_



![Image media import](https://lh3.googleusercontent.com/_xnmxq0j_QS0/TbA7m35Pm0I/AAAAAAAAAQE/sTLKAVKG9r8/importing.png)

  _while importing, the player is fully usable_


Xnoise is always running in a **single instance**, so that music files that are associated with it, will always be added to the tracklist instead of starting a new instance of xnoise. 

A local database (sqlite) is used for caching the metadata and media locations. 
Song tags are imported via taglib. All that gives Xnoise a really great speed!

The search function helps you find artists, albums, and titles in your local media collection:

![Image search](https://lh4.googleusercontent.com/-FdER1yvKSZ4/TgmFJjcA4XI/AAAAAAAAAR0/9vTJNo1De9E/xnoise_scrot_20110622_2.jpg)

  _Entering a search term allows quick finding of media from the library_ 


Columns are customizable in visibility, order and width. Everything is restored on the next start. 
There is autoscaling for the columns, that will only use available space and though avoid horizontal scrollbars.

***
 
Xnoise is written in **vala**. This means it is **compiled to pure Gobject/C** and therfore very **fast and memory efficient** compared with other music players written in mono or python.

***

Localization:
By now, xnoise is available with localizations for chinese(TW), english, french, german, hebrew, hungarian, polish, portugese, russian, spanish (CO and ES).

***

The license of xnoise is GNU GPL v2 or later. There is a license exeption for the distribution together with non-GPL compatible gstreamer plugins (the exception statement is optional). 

***
 
**[xnoise home page](http://www.xnoise-media-player.com/)**

**[xnoise wiki home](https://github.com/shuerhaaken/xnoise/wiki/Home)**

**[xnoise mailing list](http://groups.google.com/group/xnoise)**

**[xnoise on Ubuntu via PPA](https://launchpad.net/~shkn/+archive/xnoise)**

**PLEASE FEEL FREE TO JOIN THE DISCUSSION ON THE GUI, BEHAVIOR AND FUTURE FEATURES OF XNOISE !**

