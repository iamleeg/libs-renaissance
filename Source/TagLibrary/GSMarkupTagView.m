/* -*-objc-*-
   GSMarkupTagView.m

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
#include "GSMarkupTagView.h"
#include "GSAutoLayoutDefaults.h"

#ifndef GNUSTEP
# include <Foundation/Foundation.h>
# include <AppKit/AppKit.h>
# include "GNUstep.h"
#else
# include <Foundation/NSString.h>
# include <AppKit/NSView.h>
#endif

#include <NSViewSize.h>

@implementation GSMarkupTagView

+ (NSString *) tagName
{
  return @"view";
}

+ (Class) platformObjectClass
{
  return [NSView class];
}

+ (BOOL) useInstanceOfAttribute
{
  return YES;
}

- (id) initPlatformObject: (id)platformObject
{
  /* Choose a reasonable size to start with.  Starting with a zero
   * size is not a good choice as it can easily cause problems of
   * subviews getting negative sizes etc.  If we have a hardcoded
   * size, it's a good idea to use it from the start; if so, we'll
   * also skip the -sizeToFitContent later.
   */
  NSRect frame = NSMakeRect (0, 0, 100, 100);
  NSString *width;
  NSString *height;

  width = [_attributes objectForKey: @"width"];
  if (width != nil)
    {
      float w = [width floatValue];
      if (w > 0)
	{
	  frame.size.width = w;
	}
    }
  
  height = [_attributes objectForKey: @"height"];
  if (height != nil)
    {
      float h = [height floatValue];
      if (h > 0)
	{
	  frame.size.height = h;
	}
    }

  platformObject = [platformObject initWithFrame: frame];

  /* nextKeyView, previousKeyView are outlets :-), done
   * automatically.  */

  return platformObject;
}

/* This is done at init time, but should be done *after* all other
 * initialization - so it is in a separate method which subclasses
 * can/must call at the end of their initPlatformObject: method.  */
- (id) postInitPlatformObject: (id)platformObject
{
  /* If no width or no height is specified, we need to use
   * -sizeToFitContent to choose a good size.
   */
  if (([_attributes objectForKey: @"width"] == nil)
      || ([_attributes objectForKey: @"height"] == nil))
    {
      [(NSView *)platformObject sizeToFitContent];
    }

  /* Now set the hardcoded frame if any.  */
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
	[platformObject setFrame: frame];
      }
  }

  /* We don't normally use autoresizing masks, except in special
   * cases: mostly stuff contained directly inside NSBox objects.  In
   * that case, any changes in the size of the NSBox will propagate to
   * the object inside it via its autoresizing mask.
   *
   * So we want to convert the autolayout flags of the view into a
   * corresponding autoresizing mask so that it all works as expected
   * when used inside a NSBox - ie, if you set halign="center" into an
   * NSBox that is itself set to expand, then when the NSBox expands,
   * the view inside is centered.
   *
   * Please note that if we are the window's content view, this could
   * be a problem because on Apple Mac OS X the autoresizing mask gets
   * used (in the vertical direction) and might cause the view to
   * overwrite the window's titlebar (tested with 10.4)!  For that
   * reason, in GSMarkupTagWindow we always set the autoresizing mask
   * of a window's content view to NSViewWidthSizable |
   * NSViewHeightSizable.
   */
  {
    unsigned int autoresizingMask = 0;

    {
      /* Read the halign from the tag attributes, and if nothing is
       * found, from the default for that view.  */
      int autoLayoutHorizontalAlignment = 0;
      autoLayoutHorizontalAlignment = [self gsAutoLayoutHAlignment];
      if (autoLayoutHorizontalAlignment == 255)
	{
	  autoLayoutHorizontalAlignment = [platformObject 
					    autoLayoutDefaultHorizontalAlignment];
	}
      
      switch (autoLayoutHorizontalAlignment)
	{
	case GSAutoLayoutExpand: 
	case GSAutoLayoutWeakExpand: 
	  autoresizingMask |= NSViewWidthSizable; 
	  break;
	case GSAutoLayoutAlignBottom:
	  autoresizingMask |= NSViewMaxXMargin;
	  break;
	case GSAutoLayoutAlignCenter:
	  autoresizingMask |= NSViewMaxXMargin | NSViewMinXMargin;
	  break;
	case GSAutoLayoutAlignTop:
	  autoresizingMask |= NSViewMinXMargin;
	  break;
	}
    }

    {
      /* Read the valign from the tag attributes, and if nothing is
       * found, from the default for that view.  */
      int autoLayoutVerticalAlignment = 0;

      autoLayoutVerticalAlignment = [self gsAutoLayoutVAlignment];
      if (autoLayoutVerticalAlignment == 255)
	{
	  autoLayoutVerticalAlignment = [platformObject 
					  autoLayoutDefaultVerticalAlignment];
	}
      
      switch (autoLayoutVerticalAlignment)
	{
	case GSAutoLayoutExpand: 
	case GSAutoLayoutWeakExpand: 
	  autoresizingMask |= NSViewHeightSizable; 
	  break;
	case GSAutoLayoutAlignBottom:
	  autoresizingMask |= NSViewMaxYMargin;
	  break;
	case GSAutoLayoutAlignCenter:
	  autoresizingMask |= NSViewMaxYMargin | NSViewMinYMargin;
	  break;
	case GSAutoLayoutAlignTop:
	  autoresizingMask |= NSViewMinYMargin;
	  break;
	}
    }

    [platformObject setAutoresizingMask: autoresizingMask];
  }

  /* You can set autoresizing masks if you're trying to build views in the
   * old hardcoded size style.  Else, it's pretty useless.
   *
   * Subclasses have each one their own default autoresizing mask.  We
   * only modify the existing one if a different one is specified in
   * the .gsmarkup file.  The format for specifying them is as in
   * autoresizingMask="hw" for NSViewHeightSizable |
   * NSViewWidthSizable, and autoresizingMask="" for nothing,
   * autoresizingMask="xXhy" for NSViewMinXMargin | NSViewMaxXMargin |
   * NSViewHeightSizable | NSViewMinYMargin.
   */
  {
    NSString *autoresizingMaskString = [_attributes objectForKey: 
						      @"autoresizingMask"];

    if (autoresizingMaskString != nil)
      {
	int i, count = [autoresizingMaskString length];
	unsigned newAutoresizingMask = 0;
	
	for (i = 0; i < count; i++)
	  {
	    unichar c = [autoresizingMaskString characterAtIndex: i];

	    switch (c)
	      {
	      case 'h':
		newAutoresizingMask |= NSViewHeightSizable;
		break;
	      case 'w':
		newAutoresizingMask |= NSViewWidthSizable;
		break;
	      case 'x':
		newAutoresizingMask |= NSViewMinXMargin;
		break;
	      case 'X':
		newAutoresizingMask |= NSViewMaxXMargin;
		break;
	      case 'y':
		newAutoresizingMask |= NSViewMinYMargin;
		break;
	      case 'Y':
		newAutoresizingMask |= NSViewMaxYMargin;
		break;
	      default:
		break;
	      }
	  }
      if (newAutoresizingMask != [platformObject autoresizingMask])
        {
          [platformObject setAutoresizingMask: newAutoresizingMask];
        }
      }
  }
  
  {
    /* This attribute is only there for people wanting to use the old
     * legacy OpenStep autoresizing system.  We ignore it otherwise.
     */
    int autoresizesSubviews = [self boolValueForAttribute: @"autoresizesSubviews"];

    if (autoresizesSubviews == 0)
      {
	[platformObject setAutoresizesSubviews: NO];
      }
    else if (autoresizesSubviews == 1)
      {
	[platformObject setAutoresizesSubviews: YES];
      }
  }

  if ([self boolValueForAttribute: @"hidden"] == 1)
    {
      [platformObject setHidden: YES];
    }

  {
    NSString *toolTip = [self localizedStringValueForAttribute: @"toolTip"];
    if (toolTip != nil)
      {
	[platformObject setToolTip: toolTip];
      }
  }

  if (([self class] == [GSMarkupTagView class]) 
      || [self shouldTreatContentAsSubviews])
    {
      /* Extract the contents of the tag.  Contents are subviews that
       * get added to us.  This should only be used in special cases
       * or when the (legacy) OpenStep autoresizing system is used
       * (also, splitviews use it).  In all other cases, vbox and hbox
       * and similar autoresizing containers should be used.
       */
      int i, count = [_content count];
      
      /* Go in the order found in the XML file, so that the list of
       * views in the XML file goes from the ones below to the
       * ones above.
       * Ie, in
       *  <view id="1">
       *    <view id="2" />
       *    <view id="3" />
       *  </view>
       * view 3 appears over view 2.
       */
      for (i = 0; i < count; i++)
	{
	  GSMarkupTagView *v = [_content objectAtIndex: i];
	  NSView *view = [v platformObject];
	  
	  if (view != nil  &&  [view isKindOfClass: [NSView class]])
	    {
	      [platformObject addSubview: view];
	    }
	}
    }

  return platformObject;
}

/* This is ignored unless it returns YES, in which cases it forces
 * loading all content tags as subviews.
 */
- (BOOL) shouldTreatContentAsSubviews
{
  return NO;
}

- (int) gsAutoLayoutHAlignment
{
  NSString *halign;

  if ([self boolValueForAttribute: @"hexpand"] == 1)
    {
      return GSAutoLayoutExpand;
    }

  halign = [_attributes objectForKey: @"halign"];

  if (halign != nil)
    {
      if ([halign isEqualToString: @"expand"])
	{
	  return GSAutoLayoutExpand;
	}
      else if ([halign isEqualToString: @"wexpand"])
	{
	  return GSAutoLayoutWeakExpand;
	}
      else if ([halign isEqualToString: @"left"])
	{
	  return GSAutoLayoutAlignBottom;
	}
      else if ([halign isEqualToString: @"bottom"])
	{
	  return GSAutoLayoutAlignBottom;
	}
      else if ([halign isEqualToString: @"min"])
	{
	  /* The 'min' and 'max' values for 'halign' and 'valign' were
	   * deprecated on 30 Mar 2008; remove them on 30 Mar 2009.
	   */
	  NSLog (@"The 'min' value of a 'halign' attribute is obsolete; please replace it with 'bottom'");
	  return GSAutoLayoutAlignBottom;
	}
      else if ([halign isEqualToString: @"center"])
	{
	  return GSAutoLayoutAlignCenter;
	}
      else if ([halign isEqualToString: @"right"])
	{
	  return GSAutoLayoutAlignTop;
	}
      else if ([halign isEqualToString: @"top"])
	{
	  return GSAutoLayoutAlignTop;
	}
      else if ([halign isEqualToString: @"max"])
	{
	  /* The 'min' and 'max' values for 'halign' and 'valign' were
	   * deprecated on 30 Mar 2008; remove them on 30 Mar 2009.
	   */
	  NSLog (@"The 'max' value of a 'halign' attribute is obsolete; please replace it with 'top'");
	  return GSAutoLayoutAlignTop;
	}
    }

  return 255;
}

- (int) gsAutoLayoutVAlignment
{
  NSString *valign;

  if ([self boolValueForAttribute: @"vexpand"] == 1)
    {
      return GSAutoLayoutExpand;
    }

  valign = [_attributes objectForKey: @"valign"];

  if (valign != nil)
    {
      if ([valign isEqualToString: @"expand"])
	{
	  return GSAutoLayoutExpand;
	}
      else if ([valign isEqualToString: @"wexpand"])
	{
	  return GSAutoLayoutWeakExpand;
	}
      else if ([valign isEqualToString: @"bottom"])
	{
	  return GSAutoLayoutAlignBottom;
	} 
      else if ([valign isEqualToString: @"min"])
	{
	  /* The 'min' and 'max' values for 'halign' and 'valign' were
	   * deprecated on 30 Mar 2008; remove them on 30 Mar 2009.
	   */
	  NSLog (@"The 'min' value of a 'valign' attribute is obsolete; please replace it with 'bottom'");
	  return GSAutoLayoutAlignBottom;
	}
      else if ([valign isEqualToString: @"center"])
	{
	  return GSAutoLayoutAlignCenter;
	}
      else if ([valign isEqualToString: @"top"])
	{
	  return GSAutoLayoutAlignTop;
	}
      else if ([valign isEqualToString: @"max"])
	{
	  /* The 'min' and 'max' values for 'halign' and 'valign' were
	   * deprecated on 30 Mar 2008; remove them on 30 Mar 2009.
	   */
	  NSLog (@"The 'max' value of a 'valign' attribute is obsolete; please replace it with 'top'");
	  return GSAutoLayoutAlignTop;
	}
    }

  return 255;
}

+ (NSArray *) localizableAttributes
{
  return [NSArray arrayWithObject: @"toolTip"];
}

@end
