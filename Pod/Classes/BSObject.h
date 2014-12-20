//
//  BSObject.h
//  Pods
//
//  Created by Blair Mitchelmore on 2014-12-20.
//
//

#import <Foundation/Foundation.h>

@interface BSObject : NSObject
+ (instancetype)buildFromJson:(NSDictionary *)json;
- (void)updateFromJson:(NSDictionary *)json;
- (NSDictionary *)jsonFromWhitelist:(NSArray *)keys;
- (NSDictionary *)json;
- (void)inited __attribute__((objc_requires_super));
- (void)built __attribute__((objc_requires_super));
@end
