/* -*-objc-*-
   GSMarkupTagPopUpButtonItem.m

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: November 2002

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
#include "GSMarkupTagPopUpButtonItem.h"


#ifndef GNUSTEP
# include <Foundation/Foundation.h>
# include <AppKit/AppKit.h>
# include "GNUstep.h"
#else
# include <Foundation/NSArray.h>
# include <Foundation/NSDictionary.h>
# include <Foundation/NSString.h>
# include <AppKit/NSMenuItem.h>
#endif

@implementation GSMarkupTagPopUpButtonItem
+ (NSString *) tagName
{
  return @"popUpButtonItem";
}

/* The enclosing GSMarkupTagPopUpButton will extract the 'title'
 * attribute from us and add an entry with that title to itself.  It
 * will then call setPlatformObject: to set the platform object to be
 * that entry.  It will then manually call initPlatformObject: to have
 * it set the basic attributes.
 *
 * We need to have a _platformObject here, because the target of this
 * object might be set using an outlet.
 */

/* Will never be called.  */
- (id) allocPlatformObject
{
  return nil;
}

- (id) initPlatformObject: (id)platformObject
{
  /* title done by the enclosing popupbutton  */

  /* tag */
  {
    NSString *tag = [_attributes objectForKey: @"tag"];
    if (tag != nil)
      {
	[platformObject setTag: [tag intValue]];
      }
  }
  
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

  /* keyEquivalent */
  {
    NSString *keyEquivalent = [_attributes objectForKey: @"keyEquivalent"];
    
    /* Backward-compatible hack to support obsolete attribute 'key'.
     * It will be removed one year from now, on 4 March 2009.
     */
    if (keyEquivalent == nil)
      {
	keyEquivalent = [_attributes objectForKey: @"key"];
	if (keyEquivalent != nil)
	  {
	    NSLog (@"The 'key' attribute of the <popUpButtonItem> tag is obsolete; please replace it with 'keyEquivalent'");
	  }
      }

    /* Mac OS X barfs on a nil keyEquivalent.  */    
    if (keyEquivalent != nil)
      {
	[platformObject setKeyEquivalent: keyEquivalent];
      }
  }
  
  
  /* target done as an outlet.  */
  
  return platformObject;
}

+ (NSArray *) localizableAttributes
{
  return [NSArray arrayWithObject: @"title"];
}

@end
