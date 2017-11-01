//
//  NLBrowseList.h
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLListDataSource.h"
#import "NLSourceMediaServer.h"

// If there are at least this many items and the list appears to be sorted, then we will
// try to divide into sections and present an A-Z index
#define SECTIONS_ITEM_COUNT_THRESHOLD  32

@class NLBrowseList;

@protocol NLBrowseListRoot <NSObject>

@property (readonly) NLBrowseList *presetsList;

@end

@interface NLBrowseList : NLListDataSource <NLSourceMediaServerDelegate>
{
@protected
  NLSource *_source;
  NSString *_title;
  NSString *_itemType;
}

@property (readonly) NSString *itemType;

- (id) initWithSource: (NLSource *) source title: (NSString *) title;
- (BOOL) initAlphaSections;
- (NSArray *) sectionIndices;
- (BOOL) dataPending;
- (NSString *) pendingMessage;
- (void) didReceiveMemoryWarning;
- (NLBrowseList *) browseListForItemAtIndex: (NSUInteger) index;
- (void) setServerToThisContext;

@end
