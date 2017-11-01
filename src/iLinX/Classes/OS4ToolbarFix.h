//
//  OS4ToolbarFix.h
//  iLinX
//
//  Created by mcf on 18/10/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIToolbar (OS4ToolbarFix)

- (void) fixedSetStyle: (UIBarStyle) style;
- (void) fixedSetTint: (UIColor *) tint;
- (void) fixedSetStyle: (UIBarStyle) style tint: (UIColor *) tint;

@end
