//
//  NLSourceMediaServerITunes.h
//  iLinX
//
//  Created by mcf on 19/10/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLSourceMediaServer.h"
#import "ITStatus.h"

@class NLBrowseListITunesRoot;

@interface NLSourceMediaServerITunes : NLSourceMediaServer <ITStatusDelegate>
{
@private
  ITSession *_librarySession;
  NLBrowseListITunesRoot *_browseMenu;
  NSUInteger _repeat;
}

+ (id) allocSourceWithSourceData: (NSDictionary *) sourceData libraryId: (NSString *) libraryId licence: (NSString *) licence;
- (id) initWithSourceData: (NSDictionary *) sourceData libraryId: (NSString *) libraryId licence: (NSString *) licence;

@end
