//
//  MasMsEditorViewControllerDelegate.h
//  MasMs
//
//  Created by Jack Qiu on 12/25/12.
//  Copyright (c) 2012 hpyhacking. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MasMsEditorViewControllerDelegate <NSObject>
- (void) saveSMS:(NSString *)sms;
@end
