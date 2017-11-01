//
//  PresetViewController.h
//  iLinX
//
//  Created by Tony Short on 01/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLCamera.h"

@protocol PresetViewDelegate
@required
- (void) presetChosen: (NSInteger) preset;
@end

@interface CameraPresetViewController : UIViewController 
{
@private
  NSInteger _templateID;
  
  id<PresetViewDelegate> _delegate;
  NSArray *_presetNames;
  IBOutlet UITableView *_presetTableView;
  IBOutlet UIView *_presetCellTemplatesView;
  NSMutableArray *_presetCellTemplates;
}

- (void) setCamera: (NLCamera *) camera;

@property (nonatomic, retain) id<PresetViewDelegate> delegate;

@end

@interface PresetCellTemplate : NSObject
{
  NSDictionary *_rowData;
  float _cellHeight;
}

@property (nonatomic, retain) NSDictionary *rowData;
@property float cellHeight;

@end
