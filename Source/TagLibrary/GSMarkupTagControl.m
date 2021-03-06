/* -*-objc-*-
   GSMarkupTagControl.m

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
#include "GSMarkupTagControl.h"


#ifndef GNUSTEP
# include <Foundation/Foundation.h>
# include <AppKit/AppKit.h>
# include "GNUstep.h"
#else
# include <Foundation/NSString.h>
# include <Foundation/NSDictionary.h>
# include <AppKit/NSControl.h>
#endif

@implementation GSMarkupTagControl

+ (NSString *) tagName
{
  return @"control";
}

+ (Class) platformObjectClass
{
  return [NSControl class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [super initPlatformObject: platformObject];
  
  /* action */
  {
    NSString *action = [_attributes objectForKey: @"action"];
  
    if (action != nil)    
      {
	SEL selector = NSSelectorFromString (action);
	if (selector == NULL)
	  {
	    NSLog (@"Warning: <%@> has non-existing action '%@'.  Ignored.",
		   [[self class] tagName], action);
	  }
	else
	  {
	    [platformObject setAction: selector];
	  }
      }
  }

  /* continuous */
  {
    int continuous = [self boolValueForAttribute: @"continuous"];
    
    if (continuous == 1)
      {
	[platformObject setContinuous: YES];
      }
    else if (continuous == 0)
      {
	[platformObject setContinuous: NO];
      }
  }

  /* enabled */
  {
    int enabled = [self boolValueForAttribute: @"enabled"];
    
    if (enabled == 1)
      {
	[platformObject setEnabled: YES];
      }
    else if (enabled == 0)
      {
	[platformObject setEnabled: NO];
      }
  }

  /* tag */
  {
    NSString *tag = [_attributes objectForKey: @"tag"];
    if (tag != nil)
      {
	[(NSControl *)platformObject setTag: [tag intValue]];
      }
  }

  /* sendActionOn */
  {
    NSString *sendActionOn = [_attributes objectForKey: @"sendActionOn"];
    if (sendActionOn != nil)
      {
	NSDictionary *maskValuesDictionary;
	int mask = -1;

	maskValuesDictionary 
	  = [NSDictionary
	      dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt: NSLeftMouseDownMask], @"leftMouseDown",
	      [NSNumber numberWithInt: NSLeftMouseUpMask], @"leftMouseUp",
	      [NSNumber numberWithInt: NSRightMouseDownMask], @"rightMouseDown",
	      [NSNumber numberWithInt: NSRightMouseUpMask], @"rightMouseUp",
	      [NSNumber numberWithInt: NSMouseMovedMask], @"mouseMoved",
	      [NSNumber numberWithInt: NSLeftMouseDraggedMask], @"leftMouseDragged",
	      [NSNumber numberWithInt: NSRightMouseDraggedMask], @"rightMouseDragged",
	      [NSNumber numberWithInt: NSMouseEnteredMask], @"mouseEntered",
	      [NSNumber numberWithInt: NSMouseExitedMask], @"mouseExited",
	      [NSNumber numberWithInt: NSKeyDownMask], @"keyDown",
	      [NSNumber numberWithInt: NSKeyUpMask], @"keyUp",
	      [NSNumber numberWithInt: NSFlagsChangedMask], @"flagsChanged",
	      [NSNumber numberWithInt: NSAppKitDefinedMask], @"appKeyDefined",
	      [NSNumber numberWithInt: NSSystemDefinedMask], @"systemDefined",
	      [NSNumber numberWithInt: NSApplicationDefinedMask], @"applicationDefined",
	      [NSNumber numberWithInt: NSPeriodicMask], @"periodic",
	      [NSNumber numberWithInt: NSCursorUpdateMask], @"cursorUpdate",
	      [NSNumber numberWithInt: NSScrollWheelMask], @"scrollWheel",
	      [NSNumber numberWithInt: NSOtherMouseDownMask], @"otherMouseDown",
	      [NSNumber numberWithInt: NSOtherMouseUpMask], @"otherMouseUp",
	      [NSNumber numberWithInt: NSOtherMouseDraggedMask], @"otherMouseDragged",
	      [NSNumber numberWithInt: NSAnyEventMask], @"anyEvent",
	     nil];

	mask = [self integerMaskValueForAttribute: @"sendActionOn"
		     withMaskValuesDictionary: maskValuesDictionary];
	[platformObject sendActionOn: mask];
      }
  }

  /* textAlignment */
  {
    NSString *alignment = [_attributes objectForKey: @"textAlignment"];

    /* Backwards-compatible check introduced on 27 Feb 2008, will be
     * removed on 27 Feb 2009.
     */
    if (alignment == nil)
      {
	/* Check for the old name "align"  */
	alignment = [_attributes objectForKey: @"align"];

	if (alignment != nil)
	  {
	    NSLog (@"The 'align' attribute has been renamed to 'textAlignment'.  Please update your gsmarkup files");
	  }
      }
    
    if (alignment != nil)
      {
	if ([alignment isEqualToString: @"left"])
	  {
	    [platformObject setAlignment: NSLeftTextAlignment];
	  }
	else if ([alignment isEqualToString: @"right"])
	  {
	    [platformObject setAlignment: NSRightTextAlignment];
	  }
	else if ([alignment isEqualToString: @"center"])    
	  {
	    [platformObject setAlignment: NSCenterTextAlignment];
	  }
      }
  }

  /* font */
  {
    NSFont *f = [self fontValueForAttribute: @"font"];
    if (f != nil)
      {
	[platformObject setFont: f];
      }
  }

  return platformObject;
}

@end
