//
//  AdvancedObject.h
//  BSObject
//
//  Created by Blair Mitchelmore on 2014-12-20.
//  Copyright (c) 2014 Blair Mitchelmore. All rights reserved.
//

#import "BSObject.h"

@interface AdvancedObject : BSObject
@property (nonatomic, strong) NSString *customKey;
@property (nonatomic, strong) NSString *nestedKey;
@property (nonatomic, strong) NSString *skippedOnRead;
@property (nonatomic, strong) NSString *skippedOnWrite;
@property (nonatomic, strong) NSString *firstNestedChild;
@property (nonatomic, strong) NSString *secondNestedChild;
@property (nonatomic, strong) NSString *deeplyNestedKey;
@property (nonatomic, strong) NSString *readNull;
@property (nonatomic, strong) NSString *writtenNull;
@property (nonatomic, strong) NSString *preset;
@property (nonatomic, strong) NSNumber *transformed;
@property (nonatomic, strong) NSArray *children;
@end
