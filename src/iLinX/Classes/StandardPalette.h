//
//  StandardPalette.h
//  iLinX
//
//  Created by mcf on 28/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface StandardPalette : NSObject
{
@private
  UIStatusBarStyle _statusBarStyle;
  UIColor *_buttonColour;
  UIColor *_buttonTitleColour;
  UIColor *_buttonTitleShadowColour;
  UIColor *_highlightedButtonTitleColour;
  UIColor *_highlightedButtonTitleShadowColour;
  UIColor *_standardTintColour;
  UIColor *_multizoneTintColour;
  UIColor *_placeholderTextColour;
  UIColor *_editableTextColour;
  UIColor *_tableBackgroundTintColour;
  UIColor *_tableCellColour;
  UIColor *_selectedTableCellColour;
  UIColor *_tableSeparatorColour;
  UIColor *_tableTextColour;
  UIColor *_disabledTableTextColour;
  UIColor *_selectedTableTextColour;
  UIColor *_highlightedTableTextColour;
  UIColor *_alternativeTableTextColour;
  UIColor *_smallTableTextColour;
  UIColor *_tableGroupedHeaderTextColour;
  UIColor *_tableGroupedHeaderShadowColour;
  UIColor *_tablePlainHeaderTextColour;
  UIColor *_tablePlainHeaderShadowColour;
  UIColor *_tablePlainHeaderTintColour;
  UIColor *_noItemTitleColour;
  UIColor *_customPageBackgroundColour;
}

@property (assign) UIStatusBarStyle statusBarStyle;
@property (nonatomic, retain) UIColor *buttonColour;
@property (nonatomic, retain) UIColor *buttonTitleColour;
@property (nonatomic, retain) UIColor *buttonTitleShadowColour;
@property (nonatomic, retain) UIColor *highlightedButtonTitleColour;
@property (nonatomic, retain) UIColor *highlightedButtonTitleShadowColour;
@property (nonatomic, retain) UIColor *standardTintColour;
@property (nonatomic, retain) UIColor *multizoneTintColour;
@property (nonatomic, retain) UIColor *placeholderTextColour;
@property (nonatomic, retain) UIColor *editableTextColour;
@property (nonatomic, retain) UIColor *tableBackgroundTintColour;
@property (nonatomic, retain) UIColor *tableCellColour;
@property (nonatomic, retain) UIColor *selectedTableCellColour;
@property (nonatomic, retain) UIColor *tableSeparatorColour;
@property (nonatomic, retain) UIColor *tableTextColour;
@property (nonatomic, retain) UIColor *disabledTableTextColour;
@property (nonatomic, retain) UIColor *selectedTableTextColour;
@property (nonatomic, retain) UIColor *highlightedTableTextColour;
@property (nonatomic, retain) UIColor *alternativeTableTextColour;
@property (nonatomic, retain) UIColor *smallTableTextColour;
@property (nonatomic, retain) UIColor *tableGroupedHeaderTextColour;
@property (nonatomic, retain) UIColor *tableGroupedHeaderShadowColour;
@property (nonatomic, retain) UIColor *tablePlainHeaderTextColour;
@property (nonatomic, retain) UIColor *tablePlainHeaderShadowColour;
@property (nonatomic, retain) UIColor *tablePlainHeaderTintColour;
@property (nonatomic, retain) UIColor *noItemTitleColour;
@property (nonatomic, retain) UIColor *customPageBackgroundColour;

+ (void) initialise;
+ (void) setTintForNavigationBar: (UINavigationBar *) navigationBar;
+ (void) setTintForToolbar: (UIToolbar *) toolbar;
+ (UIColor *) backdropTint;
+ (UIColor *) timerBarTint;

+ (UIStatusBarStyle) statusBarStyle;
+ (UIColor *) buttonColour;
+ (UIColor *) buttonTitleColour;
+ (UIColor *) buttonTitleShadowColour;
+ (UIColor *) highlightedButtonTitleColour;
+ (UIColor *) highlightedButtonTitleShadowColour;
+ (UIColor *) standardTintColour;
+ (UIColor *) standardTintColourWithAlpha: (CGFloat) alpha;
+ (UIColor *) multizoneTintColour;
+ (UIColor *) multizoneTintColourWithAlpha: (CGFloat) alpha;
+ (UIColor *) placeholderTextColour;
+ (UIColor *) editableTextColour;
+ (UIColor *) tableBackgroundTintColour;
+ (UIColor *) tableCellColour;
+ (UIColor *) selectedTableCellColour;
+ (UIColor *) tableSeparatorColour;
+ (UIColor *) tableTextColour;
+ (UIColor *) disabledTableTextColour;
+ (UIColor *) selectedTableTextColour;
+ (UIColor *) highlightedTableTextColour;
+ (UIColor *) alternativeTableTextColour;
+ (UIColor *) smallTableTextColour;
+ (UIColor *) tableGroupedHeaderTextColour;
+ (UIColor *) tableGroupedHeaderShadowColour;
+ (UIColor *) tablePlainHeaderTextColour;
+ (UIColor *) tablePlainHeaderShadowColour;
+ (UIColor *) tablePlainHeaderTintColour;
+ (UIColor *) noItemTitleColour;
+ (UIColor *) customPageBackgroundColour;

@end
