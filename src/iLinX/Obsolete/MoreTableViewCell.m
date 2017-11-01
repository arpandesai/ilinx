//
//  MoreTableViewCell.m
//  NetStreams
//
//  Created by mcf on 20/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "MoreTableViewCell.h"

#if 0
@implementation MoreTableViewCell

@synthesize
  image = _image,
  selectedImage = _selectedImage,
  label = _label;

- (id) initWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
{
  if (self = [super initWithFrame: frame reuseIdentifier: reuseIdentifier])
  {
    _image = nil;
    _selectedImage = nil;
    _imageView = nil;
    _label = nil;
        
    UILabel *label = [[UILabel alloc] initWithFrame: CGRectZero];
    
    _imageView = [[UIImageView alloc] initWithFrame: CGRectZero];
    [self.contentView addSubview: _imageView];
    
    // Set the label view to have a clear background and a 20 point font
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize: 20];
    label.textColor = [UIColor blackColor];
    label.highlightedTextColor = [UIColor whiteColor];
    self.label = label;
    [self.contentView addSubview: label];
    [label release];
  }
  
  return self;
}

- (void) setSelected: (BOOL) selected animated: (BOOL) animated
{
  _label.highlighted = selected;
  if (selected)
    _imageView.image = _selectedImage;
  else
    _imageView.image = _image;
  [super setSelected: selected animated: animated];
}

- (void) layoutSubviews
{
  [super layoutSubviews];
  
  // determine the content rect for the cell. This will change depending on the
  // style of table (grouped vs plain)
  CGRect contentRect = self.contentView.bounds;
  
  // position the image tile in the content rect.
  CGRect imageRect = self.contentView.bounds;
  CGSize imageSize = _image.size;
  
  imageRect.size = CGSizeMake( 39, imageSize.height );
  imageRect = CGRectOffset( imageRect, 10, (39 - imageSize.height) / 2 );
  _imageView.frame = imageRect;
  
  // position the item name in the content rect
  CGRect labelRect = contentRect;
  
  labelRect.origin.x = labelRect.origin.x + 56;
  labelRect.origin.y = labelRect.origin.y + 3;
  _label.frame = labelRect;	
}

- (void) setTitle: (NSString *) title image: (UIImage *) image selectedImage: (UIImage *) selectedImage
{
  self.image = image;
  if (selectedImage == nil)
    self.selectedImage = image;
  else
    self.selectedImage = selectedImage;
  self.label.text = title;
  [_imageView setNeedsDisplay];
  [_label setNeedsDisplay];
}

- (void) dealloc
{
  //[_imageView release];
  [_label release];
  //[_image release];
  //[_selectedImage release];
  [super dealloc];
}


@end
#endif