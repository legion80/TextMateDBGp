# TextMateDBGp.tmplugin

Inspired by the [Missing Drawer](https://github.com/jezdez/textmate-missingdrawer) and [MacGDBp](http://www.bluestatic.org/software/macgdbp/) projects, the TextMateDBGp plugin extends [TextMate](http://macromates.com/) with a simple [DBGp](http://xdebug.org/docs-dbgp.php)-compliant debugger for PHP in an Xcode-inspired interface.

![Screenshot](https://github.com/downloads/legion80/TextMateDBGp/ScreenShot.png)

## Features

The TextMateDBGp plugin supports the following features:

* Quickly filter your source tree (jump to the filter search widget with ⌥⌘J)
* Use the bookmarking feature of TextMate to setup your breakpoints
* When initializing a debug session, break at the first line
* During debugging, turn all breakpoints off
* Perform standard debugger tasks: step into a function, step out of a function, step over a line, continue execution
* Inspect local and global variables

The interface may be placed to the left or right of the main content area, and only appears when opening a folder or a TextMate project.

The top toolbar shows three views: the navigator, the debugger, and the breakpoint views.

To create a breakpoint, click in the gutter space between the line numbers and the left edge of the content view. You will see the breakpoint appear in the breakpoint view:

![Adding a breakpoint](https://github.com/downloads/legion80/TextMateDBGp/ScreenShotBookmarks.png)

### Known issues

Because of quirks in TextMate, bookmarks are not detected unless the file is closed in the content area. When you toggle a breakpoint with your mouse, the plugin will close and re-open the file. It is suggested you save all of your files (⌥⌘S) prior to setting up your breakpoints to avoid dialogs.

You might need to toggle a breakpoint multiple times. You may also refresh all the breakpoints of your project by clicking the Refresh button in the breakpoint view.

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

## Authors

The source code is released under the MIT license. Please see LICENSE for more information.

This project is a fork of the [Missing Drawer](https://github.com/jezdez/textmate-missingdrawer) plugin. TextMateDBGp also leverages the following third-party projects:

* [jrswizzle](https://github.com/rentzsch/jrswizzle) - An interface for swapping Objective-C method implementations.
* [CocoaAsyncSocket](http://code.google.com/p/cocoaasyncsocket/) - An asynchronous socket networking library for Cocoa.