//
//  NLBrowseListITunesType.h
//  iLinX
//
//  Created by mcf on 12/11/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ITSession;

@interface NLBrowseListITunesType : NSObject
{
@private
  ITSession *_session;
  NSString *_name;
  NSArray *_typeData;
  NSSet *_filter;
  NSMutableDictionary *_parameters;
}

@property (readonly) NSString *name;
@property (readonly) NSString *childType;

+ (NLBrowseListITunesType *) allocTypeDataForType: (NSString *) type session: (ITSession *) session
                                      parentFilter: (NSSet *) parentFilter item: (NSDictionary *) item;

- (NSArray *) specialItems;
- (NSString *) listItemsCommand;
- (BOOL) isLeafType;
- (NLBrowseListITunesType *) allocTypeForChildIndex: (NSUInteger) index inItems: (NSArray *) items;
- (NSString *) selectCommandForChildIndex: (NSUInteger) index inItems: (NSArray *) items;

@end
