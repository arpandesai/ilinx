//
//  NLServiceAVSettings.m
//  iLinX
//
//  Created by Tony Short on 27/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "NLServiceAVSettings.h"
#import "NLRoom.h"

@implementation NLServiceAVSettings

-(NLRenderer*)renderer
{
	return _room.renderer;
}

@end
