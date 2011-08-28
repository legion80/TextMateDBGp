# TextMateDBGp.tmplugin

Inspired by the [Missing Drawer](https://github.com/jezdez/textmate-missingdrawer) and [MacGDBp](http://www.bluestatic.org/software/macgdbp/) projects, the TextMateDBGp plugin extends [TextMate](http://macromates.com/) with a simple [DBGp](http://xdebug.org/docs-dbgp.php)-compliant debugger for PHP in an Xcode-inspired interface.

![Screenshot](https://github.com/downloads/legion80/TextMateDBGp/ScreenShotDebug.png)

The TextMateDBGp plugin supports the following features:

* Filter your source tree based on the file name
* Use the bookmarking feature of TextMate to setup your breakpoints
* When initializing a debug session, break at the first line
* During debugging, toggle all breakpoints
* Perform standard debugger tasks: step into a function, step out of a function, step over a line, continue execution
* Inspect local and global variables

## Setup

The plugin requires OSX Lion (10.7).

### Installation

Download the latest version from the [project download page](http://github.com/legion80/TextMateDBGp/downloads) and double click the TextMateDBGp.tmplugin file to install.

### Uninstallation

Delete the TextMateDBGp plugin from the TextMate PlugIns directory in your Library (`~/Library/Application Support/TextMate/PlugIns`).

	rm -r "$HOME/Library/Application Support/TextMate/PlugIns/TextMateDBGp.tmplugin"

### Configuration

You can configure TextMateDBGp by going to TextMate's preferences (⌘,), clicking the double arrow icon at the top-right area of the window, and selecting TextMateDBGp. You may:

* Change the sidebar's color

Switch the location of the interface through the `View > Project Drawer` menu item.

## Using the TextMateDBGp plugin

When you open a TextMate project or a folder, the normal project drawer gets converted to a sidebar that sits next to the main content. The sidebar interface may be placed to the left or right of the main content area.

The sidebar is managed by a toolbar where you can toggle among three views: the navigator, the debugger, and the breakpoint views.

### Navigator view

Use the search field at the bottom of the sidebar to filter your source tree:

<center>![Screenshot](https://github.com/downloads/legion80/TextMateDBGp/ScreenShotFilter.png)</center>

You may use the wildcard characters "`*`" (0 to any length of characters) and "`?`" (exactly one character) in your filter search term.

### Debugger view

The plugin was originally written to debug PHP on servers using Xdebug. Be sure your server has the following lines in its `php.ini` file:

    [xdebug]
    zend_extension="/path/to/xdebug.so"
    xdebug.remote_enable = 1
    xdebug.remote_autostart = 1
    xdebug.remote_port = 9000
    
TextMateDBGp starts to listen for incoming connections when you click the "Connect" button in the debugger view. You may halt an active debugging session by clicking the button again. When a connection is made it will appear in the bottom toolbar, along with its status.

The view is divided into two sections. The top section shows the current stack trace, and the bottom section shows the variables relevant to the selected stack frame.

Toggle the "1" button in the top toolbar on if you want the debugger session to break on the first line. The breakpoint button next to it allows you to toggle all of the active breakpoints.

Use the debugger buttons on the left to continue, step over, step in, or step out.

### Breakpoints view

To create a breakpoint, click in the gutter space between the line numbers and the left edge of the content view. You will see the breakpoint appear in the breakpoint view:

<center>![Adding a breakpoint](https://github.com/downloads/legion80/TextMateDBGp/ScreenShotBookmarks.png)</center>

### Shortcuts

* ⌥⌘J - Jump to the search field in the navigator view to filter your project file tree
* ^⌘1 - Switch to the navigator view
* ^⌘2 - Switch to the debugger view
* ^⌘3 - Switch to the breakpoints view

### Known issues

Because of quirks in TextMate, bookmarks are not detected unless the file is closed in the content area. When you toggle a breakpoint with your mouse, the plugin will close and re-open the file. It is suggested you save all of your files (⌥⌘S) prior to setting up your breakpoints to avoid dialogs.

You might need to toggle a breakpoint multiple times. You may also refresh all the breakpoints of your project by clicking the Refresh button in the breakpoint view.

## Authors

The source code is released under the MIT license. Please see LICENSE for more information.

This project is a fork of the [Missing Drawer](https://github.com/jezdez/textmate-missingdrawer) plugin. TextMateDBGp also leverages the following third-party projects:

* [jrswizzle](https://github.com/rentzsch/jrswizzle) - An interface for swapping Objective-C method implementations.
* [CocoaAsyncSocket](http://code.google.com/p/cocoaasyncsocket/) - An asynchronous socket networking library for Cocoa.