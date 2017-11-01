//
//  CustomSliderIPad.h
//  iLinX
//
//  Created by mcf on 14/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CustomSliderIPad : UISlider
{
@protected
  IBOutlet UIImageView *_leftEnd;
  IBOutlet UIImageView *_thumb;
  IBOutlet UIImageView *_alternateThumb;
  IBOutlet UIImageView *_rightEnd;
  
  BOOL _initialisedImages;
  BOOL _progressOnly;
  BOOL _showAlternateThumb;
}

@property (assign) BOOL progressOnly;
@property (assign) BOOL showAlternateThumb;
@end
