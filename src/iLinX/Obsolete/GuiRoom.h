//
//  GuiRoom.h
//  NetStreams
//
//  Created by mcf on 09/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GuiRoom : NSObject
{
  NSString *_name;
  NSMutableArray *_screens;
  NSMutableArray *_sources;
  NSString *_renderer;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *screens;
@property (nonatomic, retain) NSMutableArray *sources;
@property (nonatomic, retain) NSString *renderer;

@end

