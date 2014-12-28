//
//  BasicObject.h
//  BSObject
//
//  Created by Blair Mitchelmore on 2014-12-20.
//  Copyright (c) 2014 Blair Mitchelmore. All rights reserved.
//

#import <BSObject/BSObject.h>

@interface BasicObject : BSObject
@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSNumber *number;
@property (nonatomic, strong) NSString *longerKey;
@property (nonatomic, strong) NSDate *epochDate;
@property (nonatomic, strong) NSDate *standardDate;
@property (nonatomic, strong) NSURL *standardUrl;
@property (nonatomic, strong) NSURL *fileUrl;
@property (nonatomic, strong, readonly) NSNumber *ignored;
@end
