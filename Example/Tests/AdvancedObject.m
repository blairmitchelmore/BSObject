//
//  AdvancedObject.m
//  BSObject
//
//  Created by Blair Mitchelmore on 2014-12-20.
//  Copyright (c) 2014 Blair Mitchelmore. All rights reserved.
//

#import "AdvancedObject.h"
#import "BasicObject.h"

@implementation AdvancedObject
+ (Class)entryClassForChildren {
    return [BasicObject class];
}
+ (NSNumber *)transformedValueFromJsonForTransformed:(NSString *)original {
    return @([original integerValue]);
}
+ (NSString *)transformedValueToJsonForTransformed:(NSNumber *)original {
    return [original stringValue];
}
+ (NSNumber *)defaultValueForPreset {
    return @40392;
}
+ (NSString *)jsonKeyForCustomKey {
    return @"different_key";
}
+ (NSString *)jsonKeyForNestedKey {
    return @"nested.value";
}
+ (NSString *)jsonKeyForDeeplyNestedKey {
    return @"deeply.nested.fields.test";
}
+ (NSString *)jsonKeyForFirstNestedChild {
    return @"pair.first";
}
+ (NSString *)jsonKeyForSecondNestedChild {
    return @"pair.second";
}
+ (BOOL)shouldDeserializeSkippedOnRead {
    return NO;
}
+ (BOOL)shouldSerializeSkippedOnWrite {
    return NO;
}
+ (BOOL)shouldDeserializeNullsForReadNull {
    return YES;
}
+ (BOOL)shouldSerializeNullsForWrittenNull {
    return YES;
}
@end
