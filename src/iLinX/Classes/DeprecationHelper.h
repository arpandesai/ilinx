//
//  DeprecationHelper.h
//  foocall
//
//  Created by mcf on 14/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIButton (DeprecationHelper)

- (UIFont *) titleLabelFont;
- (void) setTitleLabelFont: (UIFont *) font;
- (void) setTitleLabelShadowOffset: (CGSize) shadowOffset;

@end

@interface UITableViewCell (DeprecationHelper)

- (id) initDefaultWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier;
- (UIFont *) labelFont;
- (void) setAccessoryWhenEditing: (UITableViewCellAccessoryType) accessoryType;
- (void) setHasAccessoryWhenEditing: (BOOL) hasAccessory;
- (void) setLabelFont: (UIFont *) font;
- (void) setLabelImage: (UIImage *) image;
- (void) setLabelSelectedImage: (UIImage *) image;
- (NSString *) labelText;
- (void) setLabelText: (NSString *) text;
- (void) setLabelTextAlignment: (UITextAlignment) textAlignment;
- (void) setLabelTextColor: (UIColor *) textColor;

@end

@interface UIFont (DeprecationHelper)

- (CGFloat) lineSpacing;

@end
