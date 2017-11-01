//
//  MultiRoomSelectViewController.h
//  iLinX
//
//  Created by Tony Short on 01/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MultiRoomSelectViewDelegate
@required
- (void) multiRoomChosen: (NSInteger) multiRoomSelect;
@end

@interface MultiRoomSelectViewController : UIViewController 
{
@private
  NSInteger _templateID;
  
  id<MultiRoomSelectViewDelegate> _delegate;
  NSArray *_multiRoomSelectNames;
  IBOutlet UITableView *_multiRoomSelectTableView;
  
  IBOutlet UIView *_multiRoomSelectCellTemplatesView;
  NSMutableArray *_multiRoomSelectCellTemplates;
}

- (void) setZones: (NSArray *) zones;

@property (nonatomic, retain) id<MultiRoomSelectViewDelegate> delegate;

@end

@interface MultiRoomSelectCellTemplate : NSObject
{
  NSDictionary *_rowData;
  float _cellHeight;
}

@property (nonatomic, retain) NSDictionary *rowData;
@property float cellHeight;

@end
