/* -*-objc-*-
   GSMarkupTagWindow.m

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: March 2002

   This file is part of GNUstep Renaissance

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
#include <TagCommonInclude.h>
#include "GSMarkupTagWindow.h"
#include "GSMarkupTagView.h"
#include "GSAutoLayoutDefaults.h"
#include <NSViewSize.h>

#ifndef GNUSTEP
# include <Foundation/Foundation.h>
# include <AppKit/AppKit.h>
# include "GNUstep.h"
#else
# include <Foundation/NSString.h>
# include <AppKit/NSView.h>
# include <AppKit/NSWindow.h>
#endif

@implementation GSMarkupTagWindow
+ (NSString *) tagName
{
  return @"window";
}

+ (Class) platformObjectClass
{
  return [NSWindow class];
}

+ (BOOL) useInstanceOfAttribute
{
  return YES;
}

- (id) initPlatformObject: (id)platformObject
{
  /* Default style is like NSWindow itself, it's to have everything.  */
  unsigned style = NSTitledWindowMask | NSClosableWindowMask 
    | NSMiniaturizableWindowMask | NSResizableWindowMask;
  unsigned backingType = NSBackingStoreBuffered;
  NSRect contentRect = NSMakeRect (200, 324, 162, 100); /* golden ratio */
  NSView *contentView = nil;

  /* When these are set, we forcefully set max size in that direction
   * to prevent making the window bigger in that direction.  */
  BOOL forbidHorizontalResize = NO;
  BOOL forbidVerticalResize = NO;
  
  /* But attributes can change that.  */

  /* titled */
  if ([self boolValueForAttribute: @"titled"] == 0)
    {
      style &= ~NSTitledWindowMask;
    }

  /* closable */
  if ([self boolValueForAttribute: @"closable"] == 0)
    {
      style &= ~NSClosableWindowMask;
    }

  /* miniaturizable */
  if ([self boolValueForAttribute: @"miniaturizable"] == 0)
    {
      style &= ~NSMiniaturizableWindowMask;
    }

  /* borderless */
  if ([self boolValueForAttribute: @"borderless"] == 1)
    {
      style &= NSBorderlessWindowMask;
    }

#ifndef GNUSTEP
  /* texturedBackground */
  if ([self boolValueForAttribute: @"texturedBackground"] == 1)
    {
      style &= NSTexturedBackgroundWindowMask;
    }
#endif

  /* Now first, create the content view.  */
  if (_content != nil  &&  [_content count] > 0)
    {
      contentView = [(GSMarkupTagObject *)[_content objectAtIndex: 0] 
				      platformObject];
      if ([contentView isKindOfClass: [NSView class]])
	{
	  contentRect.size = [contentView frame].size;
	}
    }

  /* resizable - check for it first, and only fall back to our automatic
   * resizability setting if not set.
   */
  
  {
    int resizable = [self boolValueForAttribute: @"resizable"];
    if (resizable == 0)
      {
	style &= ~NSResizableWindowMask;
      }
    else if (resizable == 1)
      {
	forbidVerticalResize = NO;
	forbidHorizontalResize = NO;
	style |= NSResizableWindowMask;
      }
    else
      {
	/* resizable attribute not set - use automatic code.
	 * Automatically decide if the window is to be resizable or
	 * not.  Check the content view's specific
	 * GSAutoLayoutAlignment flags.
	 */
	if (contentView != nil  
	    &&  [contentView isKindOfClass: [NSView class]])
	  {
	    /* First, check view->hexpand, view->halign and
	     * view->vexpand, view->valign  */
	    int halign = [[_content objectAtIndex: 0] gsAutoLayoutHAlignment];
	    int valign = [[_content objectAtIndex: 0] gsAutoLayoutVAlignment];
	    
	    /* If not set, check the contentView autoLayoutDefault
	     * alignment */
	    if (halign == 255)
	      {
		if ([contentView autoLayoutDefaultHorizontalAlignment] 
		    == GSAutoLayoutExpand)
		  {
		    halign = GSAutoLayoutExpand;
		  }
	      }
	    
	    if (valign == 255)
	      {
		if ([contentView autoLayoutDefaultVerticalAlignment] 
		    == GSAutoLayoutExpand)
		  {
		    valign = GSAutoLayoutExpand;
		  }
	      }
	    
	    /* Ok, now if halign == GSAutoLayoutExpand it's
	     * appropriate to expand in that direction; if not, it's
	     * not.  Similar for valign.  */
	    if (halign == GSAutoLayoutExpand)
	      {
		if (valign == GSAutoLayoutExpand)
		  {
		    /* Expand in both directions ... this was already
		     * the default.  */
		  }
		else
		  {
		    /* Expand in horizontal but not in vertical
		     * direction.  */
		    forbidVerticalResize = YES;
		  }
	      }
	    else 
	      {
		if (valign == GSAutoLayoutExpand)
		  {
		    /* Expand in vertical but not in horizontal
		     * direction.  */
		    forbidHorizontalResize = YES;
		  }
		else
		  {
		    /* Do not expand in any direction. */
		    style &= ~NSResizableWindowMask; 
		  }
	      }
	  }
      }
  }
  
  platformObject = [platformObject initWithContentRect: contentRect
				   styleMask: style
				   backing: backingType
				   defer: NO];

  if (contentView != nil  &&  [contentView isKindOfClass: [NSView class]])
    {
      /* On Apple Mac OS X the autoresizing mask of the content view
       * matters.  If you get it wrong, you may get unexpected
       * behaviours, including overwriting the window titlebar!  To
       * prevent confusing behaviours, our content view always has a
       * standard autoresizing mask where it expands in both
       * directions to cover exactly all of the window's visible area.
       * You can always use a <vbox> or another autolayout container
       * as the content view to then control alignment of a view
       * inside it.
       */
      [contentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

      [(NSWindow *)platformObject setContentView: contentView];
    }

  /* contentWidth, contentHeight */
  {
    NSSize size = [[platformObject contentView] frame].size;
    NSString *width, *height;
    BOOL needToSetSize = NO;

    width = [_attributes objectForKey: @"contentWidth"];
    if (width != nil)
      {
	float w = [width floatValue];
	if (w > 0)
	  {
	    size.width = w;
	    needToSetSize = YES;
	  }
      }

    height = [_attributes objectForKey: @"contentHeight"];
    if (height != nil)
      {
	float h = [height floatValue];
	if (h > 0)
	  {
	    size.height = h;
	    needToSetSize = YES;
	  }
      }

    if (needToSetSize)
      {
	[platformObject setContentSize: size];
      }
  }
  

  /* x, y, width, height */
  {
    NSRect frame = [platformObject frame];
    NSString *x, *y, *width, *height;
    BOOL needToSetFrame = NO;
    
    x = [_attributes objectForKey: @"x"];
    if (x != nil)
      {
	frame.origin.x = [x floatValue];
	needToSetFrame = YES;
      }

    y = [_attributes objectForKey: @"y"];
    if (y != nil)
      {
	frame.origin.y = [y floatValue];
	needToSetFrame = YES;
      }

    width = [_attributes objectForKey: @"width"];
    if (width != nil)
      {
	float w = [width floatValue];
	if (w > 0)
	  {
	    frame.size.width = w;
	    needToSetFrame = YES;
	  }
      }

    height = [_attributes objectForKey: @"height"];
    if (height != nil)
      {
	float h = [height floatValue];
	if (h > 0)
	  {
	    frame.size.height = h;
	    needToSetFrame = YES;
	  }
      }
    if (needToSetFrame)
      {
	[platformObject setFrame: frame  display: NO];
      }
  }

  /* minWidth, minHeight */
  {
    NSSize size;
    NSString *width, *height;
    /* Attempt to automatically get the minimumSize from the contentView.  */
    NSSize minimumContentViewSize = [contentView minimumSizeForContent];
    NSRect r = NSMakeRect (0, 0, minimumContentViewSize.width,
                           minimumContentViewSize.height);

    /* By default, use the automatically compute minSize ... unless
       overridden.  */
    size = ([NSWindow frameRectForContentRect: r
                                    styleMask: [platformObject styleMask]]).size;

    width = [_attributes objectForKey: @"minWidth"];
    if (width != nil)
      {
	float w = [width floatValue];
	if (w > 0)
	  {
	    size.width = w;
	  }
      }
    
    height = [_attributes objectForKey: @"minHeight"];
    if (height != nil)
      {
	float h = [height floatValue];
	if (h > 0)
	  {
	    size.height = h;
	  }
      }

    
    [platformObject setMinSize: size];
  }

  /* maxWidth, maxHeight */
  {
    NSSize size = [platformObject maxSize];
    NSString *width, *height;
    BOOL needToSetSize = NO;

    width = [_attributes objectForKey: @"maxWidth"];
    if (width != nil)
      {
	float w = [width floatValue];
	if (w > 0)
	  {
	    size.width = w;
	    needToSetSize = YES;
	  }
      }
    else
      {
	if (forbidHorizontalResize)
	  {
	    size.width = [platformObject frame].size.width;
	    needToSetSize = YES;
	  }
      }

    height = [_attributes objectForKey: @"maxHeight"];
    if (height != nil)
      {
	float h = [height floatValue];
	if (h > 0)
	  {
	    size.height = h;
	    needToSetSize = YES;
	  }
      }
    else
      {
	if (forbidVerticalResize)
	  {
	    size.height = [platformObject frame].size.height;
	    needToSetSize = YES;
	  }
      }

    if (needToSetSize)
      {
	[platformObject setMaxSize: size];
      }
  }

  /* title */
  {
    NSString *title = [self localizedStringValueForAttribute: @"title"];
    if (title != nil)
      {
	[platformObject setTitle: title];
      }
  }

  /* center */
  {
    int center = [self boolValueForAttribute: @"center"];
    if (center == 1)
      {
	[platformObject center];
      }
  }

  /* autosaveName - this must be at the end, so that we have autosized
   * ourselves, and before ordering front, we read an eventual saved
   * frame from the user defaults, and resize to match that frame.
   * The user choice must be last, overriding both autosizing and
   * hardcoded frame! */
  {
    NSString *frameName = [_attributes objectForKey: @"autosaveName"];
    if (frameName != nil)
      {
	[platformObject setFrameUsingName: frameName];
	[platformObject setFrameAutosaveName: frameName];
      }
  }

  /* initialFirstResponder - not here - that is an outlet, is done via
   * initialFirstResponder="#quitButton" which is converted into an
   * outlet automatically by the GSMarkupDecoder engine.  */

  /* delegate - not here - outlet.  */

  /* releasedWhenClosed */
  {
    int releasedWhenClosed;
    releasedWhenClosed = [self boolValueForAttribute: @"releasedWhenClosed"];
    if (releasedWhenClosed == 1)
      {
	[platformObject setReleasedWhenClosed: YES];	
      }
    else if (releasedWhenClosed == 0)
      {
	[platformObject setReleasedWhenClosed: NO];
      }
  }

  /* backgroundColor */
  {
    NSColor *bg = [self colorValueForAttribute: @"backgroundColor"];
    if (bg != nil)
      {
	[platformObject setBackgroundColor: bg];
      }
  }

  return platformObject;
}

- (id) postInitPlatformObject: (id)platformObject
{
  /* visible, key, main - do here so it's guaranteed to be made after
   * everything for subclasses as well.  */
  int visible = [self boolValueForAttribute: @"visible"];
  int keyWindow = [self boolValueForAttribute: @"keyWindow"];

  /* By default, a window is both visible and key.  But we recognize
   * visible="no" or keyWindow="no".
   */
  if (visible != 0  &&  keyWindow != 0)
    {
      [platformObject makeKeyAndOrderFront: nil];
    }
  else if (visible != 0)
    {
      [platformObject orderFront: nil];
    }
  else if (keyWindow != 0)
    {
      [platformObject makeKeyWindow];
    }

  /* By default, a window is no the main application window.  But we
   * recognize mainWindow="yes".
   */
  {
    int mainWindow = [self boolValueForAttribute: @"mainWindow"];

    if (mainWindow == 1)
      {
	[platformObject makeMainWindow];
      }
  }

  return platformObject;
}

+ (NSArray *) localizableAttributes
{
  return [NSArray arrayWithObject: @"title"];
}

@end
