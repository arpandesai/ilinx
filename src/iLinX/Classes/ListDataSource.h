//
//  ListDataSource.h
//  iLinX
//
//  Created by mcf on 15/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ListDataSource;

@protocol ListDataDelegate <NSObject>
@optional
- (void) listDataRefreshDidStart: (id<ListDataSource>) listDataSource;
- (void) listDataRefreshDidEnd: (id<ListDataSource>) listDataSource;
- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range;
- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range;
- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range;
- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index;

@end

@protocol ListDataSource <NSObject>

- (NSString *) listTitle;
- (NSUInteger) countOfList;
- (BOOL) canBeRefreshed;
- (void) refresh;
- (BOOL) refreshIsComplete;
- (id) itemAtIndex: (NSUInteger) index;
- (NSString *) titleForItemAtIndex: (NSUInteger) index;
- (BOOL) itemIsSelectedAtIndex: (NSUInteger) index;
- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index;
- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction;
- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index;

- (NSUInteger) countOfSections;
- (NSString *) titleForSection: (NSUInteger) section;
- (NSUInteger) sectionForPrefix: (NSString *) prefix;
- (NSUInteger) countOfListInSection: (NSUInteger) section;
- (id) itemAtOffset: (NSUInteger) index inSection: (NSUInteger) section;
- (NSString *) titleForItemAtOffset: (NSUInteger) index inSection: (NSUInteger) section;
- (BOOL) itemIsSelectedAtOffset: (NSUInteger) index inSection: (NSUInteger) section;
- (id<ListDataSource>) selectItemAtOffset: (NSUInteger) index inSection: (NSUInteger) section;
- (BOOL) itemIsSelectableAtOffset: (NSUInteger) index inSection: (NSUInteger) section;

- (NSUInteger) convertFromOffset: (NSUInteger) index inSection: (NSUInteger) section;
- (NSIndexPath *) indexPathFromIndex: (NSUInteger) index;

- (void) addDelegate: (id<ListDataDelegate>) delegate;
- (void) removeDelegate: (id<ListDataDelegate>) delegate;

@property (readonly) id listDataCurrentItem;
@property (readonly) NSUInteger listDataCurrentItemIndex;
@property (readonly) NSIndexPath *listDataCurrentItemIndexPath;

@end
