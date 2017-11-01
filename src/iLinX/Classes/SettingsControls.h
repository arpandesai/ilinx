//
//  SettingsControls.h
//  iLinX
//
//  Created by mcf on 16/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NLRenderer;

@interface SettingsControls : NSObject
{
@protected
  NLRenderer *_renderer;
  UIBarStyle _style;
}

@property (readonly) BOOL rightSettingsForRenderer;

+ (SettingsControls *) allocSettingsControlsForRenderer: (NLRenderer *) renderer style: (UIBarStyle) style;

- (NSUInteger) numberOfSections;
- (NSString *) titleForSection: (NSUInteger) section;
- (CGFloat) heightForSection: (NSUInteger) section;
- (void) addControlsForSection: (NSUInteger) section toView: (UIView *) view;
- (BOOL) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags;

- (void) addLabel: (UILabel *) label to: (UIView *) view position: (CGPoint) position fontSize: (CGFloat) fontSize;
- (void) addSlider: (UISlider *) label to: (UIView *) view position: (CGPoint) position;
- (void) addVerticalSlider: (UISlider *) slider to: (UIView *) view frame: (CGRect) frame;

+ (void) addButton: (UIButton *) button to: (UIView *) view frame: (CGRect) frame;
+ (UIButton *) standardButtonWithStyle: (UIBarStyle) style;

@end
