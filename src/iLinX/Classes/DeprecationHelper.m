//
//  DeprecationHelper.m
//  foocall
//
//  Created by mcf on 14/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//
// Put all the deprecated calls in here with code that calls the non-deprecated
// alternatives if they are available on the current platform.

#import "DeprecationHelper.h"


@implementation UIButton (DeprecationHelper)

- (UIFont *) titleLabelFont
{
  if ([self respondsToSelector: @selector(titleLabel)])
    return self.titleLabel.font;
  else
  {
    //self.font;
    return [self performSelector: @selector(font)];
  }
}

- (void) setTitleLabelFont: (UIFont *) font
{
  if ([self respondsToSelector: @selector(titleLabel)])
    self.titleLabel.font = font;
  else
  {
    //self.font = font;
    [self performSelector: @selector(setFont:) withObject: font];
  }
}

- (void) setTitleLabelShadowOffset: (CGSize) shadowOffset
{
  if ([self respondsToSelector: @selector(titleLabel)])
    self.titleLabel.shadowOffset = shadowOffset;
  else
  {
    //self.titleShadowOffset = shadowOffset;
    SEL selector = @selector(setTitleShadowOffset:);
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector: selector]];
    
    [invocation setSelector: selector];
    [invocation setArgument: &shadowOffset atIndex: 2];
    [invocation invokeWithTarget: self];
  }
}

@end


@implementation UITableViewCell (DeprecationHelper)

- (id) initDefaultWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
{
  id retValue;

  if ([self respondsToSelector: @selector(initWithStyle:reuseIdentifier:)])
  {
    self.frame = frame;
    retValue = [self initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier];
  }
  else
  {
    //retValue = [super initWithFrame: frame reuseIdentifier: reuseIdentifier];
    SEL selector = @selector(initWithFrame:reuseIdentifier:);
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector: selector]];
    
    [invocation setSelector: selector];
    [invocation setArgument: &frame atIndex: 2];
    [invocation setArgument: &reuseIdentifier atIndex: 3];
    [invocation invokeWithTarget: self];
    [invocation getReturnValue: &retValue];
  }
  
  return retValue;
}

- (void) setAccessoryWhenEditing: (UITableViewCellAccessoryType) accessoryType
{
  if ([self respondsToSelector: @selector(editingAccessoryType)])
    self.editingAccessoryType = accessoryType;
}

- (void) setHasAccessoryWhenEditing: (BOOL) hasAccessory
{
  if (![self respondsToSelector: @selector(editingAccessoryType)])
  {
    //self.hidesAccessoryWhenEditing = !hasAccessory;
    SEL selector = @selector(setHasAccessoryWhenEditing:);
    BOOL hidesAccessory = !hasAccessory;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector: selector]];
    
    [invocation setSelector: selector];
    [invocation setArgument: &hidesAccessory atIndex: 2];
    [invocation invokeWithTarget: self];
  }
}

- (UIFont *) labelFont
{
  if ([self respondsToSelector: @selector(textLabel)])
    return self.textLabel.font;
  else
  {
    //self.font;
    return [self performSelector: @selector(font)];
  }
}

- (void) setLabelFont: (UIFont *) font
{
  if ([self respondsToSelector: @selector(textLabel)])
    self.textLabel.font = font;
  else
  {
    //self.font = font;
    [self performSelector: @selector(setFont:) withObject: font];
  }
}

- (void) setLabelImage: (UIImage *) image
{
  if ([self respondsToSelector: @selector(imageView)])
    self.imageView.image = image;
  else
  {
    //self.image = image;
    [self performSelector: @selector(setImage:) withObject: image];
  }
}

- (void) setLabelSelectedImage: (UIImage *) image
{
  if ([self respondsToSelector: @selector(imageView)])
    self.imageView.highlightedImage = image;
  else
  {
    //self.selectedImage = image;
    [self performSelector: @selector(setSelectedImage:) withObject: image];
  }
}

- (NSString *) labelText
{
  NSString *text;

  if ([self respondsToSelector: @selector(textLabel)])
    text = self.textLabel.text;
  else
  {
    //self.text;
    text = [self performSelector: @selector(text)];
  }
  
  return text;
}

- (void) setLabelText: (NSString *) text
{
  if ([self respondsToSelector: @selector(textLabel)])
    self.textLabel.text = text;
  else
  {
    //self.text = text;
    [self performSelector: @selector(setText:) withObject: text];
  }
}


- (void) setLabelTextAlignment: (UITextAlignment) textAlignment
{
  if ([self respondsToSelector: @selector(textLabel)])
    self.textLabel.textAlignment = textAlignment;
  else
  {
    //self.textAlignment = textAlignment;
    SEL selector = @selector(setTextAlignment:);
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector: selector]];
    
    [invocation setSelector: selector];
    [invocation setArgument: &textAlignment atIndex: 2];
    [invocation invokeWithTarget: self];
  }
}

- (void) setLabelTextColor: (UIColor *) textColor
{
  if ([self respondsToSelector: @selector(textLabel)])
    self.textLabel.textColor = textColor;
  else
  {
    //self.textColor = textColor;
    [self performSelector: @selector(setTextColor:) withObject: textColor];
  }
}

@end

@implementation UIFont (DeprecationHelper)

- (CGFloat) lineSpacing
{
  CGFloat lineSpacing;
  
  if ([self respondsToSelector: @selector(lineHeight)])
    lineSpacing = self.lineHeight;
  else
  {
    //self.leading;
    SEL selector = @selector(leading);
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector: selector]];
    
    [invocation setSelector: selector];
    [invocation invokeWithTarget: self];
    [invocation getReturnValue: &lineSpacing];
  }
  
  return lineSpacing;
}


@end
