//
//  NLBrowseList.m
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLBrowseList.h"
#import "NLSource.h"

static NSArray *SECTION_INDICES = nil;

@implementation NLBrowseList

@synthesize
  itemType = _itemType;

- (id) initWithSource: (NLSource *) source title: (NSString *) title
{
  if ((self = [super init]) != nil)
  {
    _source = source;
    _title = [title retain];
  }
  
  return self;
}

- (BOOL) initAlphaSections
{
  return FALSE;
}

- (NSArray *) sectionIndices
{
  if (SECTION_INDICES == nil)
  {
    // The section index abbreviation feature added in 3.0 is buggy; it generates an incorrect list
    // with # at the end.  So, we need to have a list that won't be compressed.  For earlier versions
    // stick with the full list.  For later versions, we're currently hoping the bug will be fixed!
    if ([[[UIDevice currentDevice] systemVersion] isEqualToString: @"3.0"])
      SECTION_INDICES = [[NSArray arrayWithObjects:
                          @"#", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M",
                          @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"Y", @"Z", nil]
                         retain];
    else
      SECTION_INDICES = [[NSArray arrayWithObjects:
                          @"#", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M",
                          @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil]
                         retain];
  }

  return SECTION_INDICES;
}

- (BOOL) dataPending
{
  return FALSE;
}

- (NSString *) pendingMessage
{
  return nil;
}

- (void) didReceiveMemoryWarning
{
}

- (NLBrowseList *) browseListForItemAtIndex: (NSUInteger) index
{
  return nil;
}

- (void) setServerToThisContext
{
  // Only relevant in NetStreams
}

- (NSString *) listTitle
{
  return _title;
}

- (void) source: (NLSourceMediaServer *) source stateChanged: (NSUInteger) state
{
}

- (void) dealloc
{
  [_title release];
  [_itemType release];
  [super dealloc];
}

@end

