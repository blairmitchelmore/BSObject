//
//  BSObject.m
//  Pods
//
//  Created by Blair Mitchelmore on 2014-12-20.
//
//

#import <objc/runtime.h>
#import "BSObject.h"

static BOOL isPropertyReadonly(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'R' && strlen(attribute) == 1) {
            return YES;
        }
    }
    return NO;
}
static NSString *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] != '@') {
            // it's a C primitive type:
            /*
             if you want a list of what will be returned for these primitives, search online for
             "objective-c" "Property Attribute Description Examples"
             apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.
             */
            NSString *details = [NSString stringWithUTF8String:attribute];
            NSString *type = [details substringWithRange:NSMakeRange(1, details.length - 1)];
            return type;
        }
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            // it's an ObjC id type:
            return @"id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@') {
            // it's another ObjC object type:
            NSString *details = [NSString stringWithUTF8String:attribute];
            if (details.length > 4) {
                NSString *type = [details substringWithRange:NSMakeRange(3, details.length - 4)];
                return type;
            } else {
                return @"";
            }
        }
    }
    return @"";
}

@interface NSString (BSObject_Helpers)
- (NSString *)underscorify;
- (NSString *)camelize;
@end

@implementation NSString (BSObject_Helpers)
- (NSString *)underscorify {
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.caseSensitive = YES;
    
    NSMutableString *builder = [NSMutableString string];
    NSString *buffer = nil;
    NSUInteger lastScanLocation = 0;
    
    while ([scanner isAtEnd] == NO) {
        if ([scanner scanCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet].invertedSet intoString:&buffer]) {
            [builder appendString:buffer];
            if ([scanner scanCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:&buffer]) {
                [builder appendString:@"_"];
                [builder appendString:[buffer lowercaseString]];
            }
        }
        
        // If the scanner location has not moved, there's a problem somewhere.
        if (lastScanLocation == scanner.scanLocation) return nil;
        lastScanLocation = scanner.scanLocation;
    }
    
    return [NSString stringWithString:builder];
}
- (NSString *)camelize {
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    
    NSMutableString *builder = [NSMutableString string];
    NSString *buffer = nil;
    NSUInteger lastScanLocation = 0;
    BOOL first = YES;
    
    while ([scanner isAtEnd] == NO) {
        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"_"] intoString:&buffer]) {
            if (first) {
                first = NO;
                [builder appendString:[buffer lowercaseString]];
            } else {
                [builder appendString:[buffer capitalizedString]];
            }
            [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"_"] intoString:nil];
        }
        
        // If the scanner location has not moved, there's a problem somewhere.
        if (lastScanLocation == scanner.scanLocation) return nil;
        lastScanLocation = scanner.scanLocation;
    }
    
    return [NSString stringWithString:builder];
}
@end


@interface NSArray (WGObject_Helpers)
- (NSArray *)mappedArrayFromBlock:(id(^)(id))block;
@end

@implementation NSArray (WGObject_Helpers)
- (NSArray *)mappedArrayFromBlock:(id(^)(id))block {
    NSMutableArray *collect = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id mapped = block(obj);
        if (mapped) [collect addObject:mapped];
    }];
    return [NSArray arrayWithArray:collect];
}
@end

@interface NSDictionary (WGObject_Helpers)
- (id)objectForKeyPath:(NSString *)keypath;
@end

@implementation NSDictionary (WGObject_Helpers)
- (id)objectForKeyPath:(NSString *)keypath {
    NSArray *components = [keypath componentsSeparatedByString:@"."];
    id current = self;
    for (NSString *key in components) {
        if ([current isKindOfClass:[NSDictionary class]]) {
            current = current[key];
        } else if ([current isKindOfClass:[NSArray class]]) {
            NSScanner *scanner = [NSScanner scannerWithString:key];
            int index;
            if ([scanner scanInt:&index] && [scanner isAtEnd]) {
                NSArray *array = (NSArray *)current;
                if (index < array.count) {
                    current = array[index];
                } else {
                    return nil;
                }
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    }
    return current;
}
@end

@interface NSMutableDictionary (WGObject_Helpers)
- (void)setObject:(id)anObject forKeyPath:(NSString *)keypath;
@end

@implementation NSMutableDictionary (WGObject_Helpers)
- (void)setObject:(id)anObject forKeyPath:(NSString *)keypath {
    id current = self;
    NSArray *components = [keypath componentsSeparatedByString:@"."];
    if (components.count == 1) {
        [self setObject:anObject forKey:keypath];
    } else {
        for (int i = 0; i < components.count; ++i) {
            BOOL last = i == components.count - 1;
            if (last) {
                NSString *key = components[i];
                if ([current isKindOfClass:[NSMutableDictionary class]]) {
                    NSMutableDictionary *dict = (NSMutableDictionary *)current;
                    [dict setObject:anObject forKey:key];
                }
            } else {
                NSString *key = components[i];
                id next = nil;
                if ([current isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = (NSDictionary *)current;
                    next = dict[key];
                } else {
                    next = nil;
                }
                if (next == nil || next == [NSNull null]) {
                    current[key] = [NSMutableDictionary dictionary];
                    current = current[key];
                } else if ([next isKindOfClass:[NSDictionary class]]) {
                    current[key] = [NSMutableDictionary dictionaryWithDictionary:next];
                    current = current[key];
                } else {
                    NSString *nextKey = components.count > i + 1 ? components[i + 1] : nil;
                    if (!nextKey) {
                        
                    }
                }
            }
        }
    }
}
@end



NSString *JsonKeyForPropertyInClass(Class klass, NSString *property) {
    NSString *key = [property underscorify];
    NSString *method = [[@"json_key_for_" stringByAppendingString:key] camelize];
    SEL selector = NSSelectorFromString(method);
    if ([klass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        key = [klass performSelector:selector];
#pragma clang diagnostic pop
    }
    return key;
}

id DefaultValueForPropertyInClass(Class klass, NSString *property) {
    id value = nil;
    NSString *key = [property underscorify];
    NSString *method = [[@"default_value_for_" stringByAppendingString:key] camelize];
    SEL selector = NSSelectorFromString(method);
    if ([klass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        value = [klass performSelector:selector];
#pragma clang diagnostic pop
    }
    return value;
}

Class EntryClassForPropertyInClass(Class klass, NSString *property) {
    Class value = nil;
    NSString *key = [property underscorify];
    NSString *method = [[@"entry_class_for_" stringByAppendingString:key] camelize];
    SEL selector = NSSelectorFromString(method);
    if ([klass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        value = [klass performSelector:selector];
#pragma clang diagnostic pop
    }
    return value;
}

NSString *DefaultTimeZoneAbbreviationForClass(Class klass) {
    NSString *method = [@"default_time_zone_abbreviation" camelize];
    SEL selector = NSSelectorFromString(method);
    NSString *abbreviation = nil;
    if ([klass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        abbreviation = [klass performSelector:selector];
#pragma clang diagnostic pop
    }
    return abbreviation;
}

NSString *TimeZoneAbbreviationForPropertyInClass(Class klass, NSString *property) {
    NSString *key = [property underscorify];
    NSString *method = [[@"time_zone_abbreviation_for_" stringByAppendingString:key] camelize];
    SEL selector = NSSelectorFromString(method);
    NSString *abbreviation = nil;
    if ([klass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        abbreviation = [klass performSelector:selector];
#pragma clang diagnostic pop
    }
    if (!abbreviation) return DefaultTimeZoneAbbreviationForClass(klass);
    return abbreviation;
}

NSTimeZone *TimeZoneForPropertyInClass(Class klass, NSString *property) {
    NSString *abbreviation = TimeZoneAbbreviationForPropertyInClass(klass, property);
    if (abbreviation) {
        return [NSTimeZone timeZoneWithAbbreviation:abbreviation];
    } else {
        return [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
}

NSString *DefaultDateFormatForClass(Class klass) {
    NSString *method = [@"default_date_format" camelize];
    SEL selector = NSSelectorFromString(method);
    NSString *format = nil;
    if ([klass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        format = [klass performSelector:selector];
#pragma clang diagnostic pop
    }
    return format;
}

NSString *DateFormatForPropertyInClass(Class klass, NSString *property) {
    NSString *key = [property underscorify];
    NSString *method = [[@"date_format_for_" stringByAppendingString:key] camelize];
    SEL selector = NSSelectorFromString(method);
    NSString *format = nil;
    if ([klass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        format = [klass performSelector:selector];
#pragma clang diagnostic pop
    }
    if (!format) return DefaultDateFormatForClass(klass);
    return format;
}

NSDateFormatter *DateFormatterForPropertyInClass(Class klass, NSString *property) {
    NSString *format = DateFormatForPropertyInClass(klass, property);
    if (format) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = format;
        formatter.timeZone = TimeZoneForPropertyInClass(klass, property);
        return formatter;
    } else {
        return nil;
    }
}

id TransformedValueFromJsonForPropertyInClass(Class klass, NSString *property, id original, BOOL *called) {
    id transformed = nil;
    NSString *key = [property underscorify];
    NSString *method = [[[@"transformed_value_from_json_for_" stringByAppendingString:key] camelize] stringByAppendingString:@":"];
    SEL selector = NSSelectorFromString(method);
    if ([klass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        transformed = [klass performSelector:selector withObject:original];
        *called = YES;
#pragma clang diagnostic pop
    } else {
        *called = NO;
    }
    return transformed;
}

id TransformedValueToJsonForPropertyInClass(Class klass, NSString *property, id original, BOOL *called) {
    id transformed = nil;
    NSString *key = [property underscorify];
    NSString *method = [[[@"transformed_value_to_json_for_" stringByAppendingString:key] camelize] stringByAppendingString:@":"];
    SEL selector = NSSelectorFromString(method);
    if ([klass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        transformed = [klass performSelector:selector withObject:original];
        *called = YES;
#pragma clang diagnostic pop
    } else {
        *called = NO;
    }
    return transformed;
}

BOOL ShouldSerializePropertyInClass(Class klass, NSString *property) {
    NSString *method = [[@"should_serialize_" stringByAppendingString:[property underscorify]] camelize];
    SEL selector = NSSelectorFromString(method);
    if ([klass respondsToSelector:selector]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[klass methodSignatureForSelector:selector]];
        invocation.selector = selector;
        invocation.target = klass;
        [invocation invoke];
        BOOL returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    return YES;
}

BOOL ShouldDeserializePropertyInClass(Class klass, NSString *property) {
    NSString *method = [[@"should_deserialize_" stringByAppendingString:[property underscorify]] camelize];
    SEL selector = NSSelectorFromString(method);
    if ([klass respondsToSelector:selector]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[klass methodSignatureForSelector:selector]];
        invocation.selector = selector;
        invocation.target = klass;
        [invocation invoke];
        BOOL returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    return YES;
}

BOOL ShouldSerializeNullsForPropertyInClass(Class klass, NSString *property) {
    NSString *method = [[@"should_serialize_nulls_for_" stringByAppendingString:[property underscorify]] camelize];
    SEL selector = NSSelectorFromString(method);
    if ([klass respondsToSelector:selector]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[klass methodSignatureForSelector:selector]];
        invocation.selector = selector;
        invocation.target = klass;
        [invocation invoke];
        BOOL returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    return NO;
}

BOOL ShouldDeserializeNullsForPropertyInClass(Class klass, NSString *property) {
    NSString *method = [[@"should_deserialize_nulls_for_" stringByAppendingString:[property underscorify]] camelize];
    SEL selector = NSSelectorFromString(method);
    if ([klass respondsToSelector:selector]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[klass methodSignatureForSelector:selector]];
        invocation.selector = selector;
        invocation.target = klass;
        [invocation invoke];
        BOOL returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    return NO;
}




@implementation BSObject

- (void)preinited {
    Class klass = [self class];
    NSDictionary *properties = [[self class] writableProperties];
    for (NSString *property in properties) {
        id value = DefaultValueForPropertyInClass(klass, property);
        if (value) [self setValue:value forKey:property];
    }
}
- (void)inited {
    
}
- (void)built {
    
}

- (id)init {
    if (!(self = [super init])) return nil;
    [self preinited];
    [self inited];
    return self;
}

+ (NSDictionary *)writableProperties {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    
    Class klass = [self class];
    while (klass != [NSObject class] && klass != [BSObject class]) {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(klass, &outCount);
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                NSString *propertyType = getPropertyType(property);
                BOOL isReadOnly = isPropertyReadonly(property);
                NSString *propertyName = [NSString stringWithUTF8String:propName];
                if (propertyName && propertyType && !isReadOnly) [results setObject:propertyType forKey:propertyName];
            }
        }
        free(properties);
        klass = [klass superclass];
    }
    
    // returning a copy here to make sure the dictionary is immutable
    return [NSDictionary dictionaryWithDictionary:results];
}

- (void)updateFromJson:(NSDictionary *)json {
    Class klass = [self class];
    NSDictionary *properties = [[self class] writableProperties];
    for (NSString *property in properties) {
        BOOL use = ShouldDeserializePropertyInClass(klass, property);
        if (!use) continue;
        
        BOOL nulls = ShouldDeserializeNullsForPropertyInClass(klass, property);
        NSString *key = JsonKeyForPropertyInClass(klass, property);
        
        id value = [json objectForKeyPath:key];
        
        BOOL called = NO;
        id transformed = TransformedValueFromJsonForPropertyInClass(klass, property, value, &called);
        if (transformed && called) value = transformed;
        if (value == nil && !nulls) continue;
        
        if (value == nil || value == [NSNull null]) {
            [self setValue:nil forKey:property];
            continue;
        }
        
        NSString *type = properties[property];
        if ([type isEqualToString:NSStringFromClass([NSNumber class])] && [value doubleValue] == 0) {
            value = nil;
        } else if ([type isEqualToString:NSStringFromClass([NSDate class])] && [value isKindOfClass:[NSString class]]) {
            NSDateFormatter *formatter = DateFormatterForPropertyInClass(klass, property);
            if (formatter) {
                value = [formatter dateFromString:value];
            } else {
                value = nil;
            }
        } else if ([type isEqualToString:NSStringFromClass([NSDate class])] && [value isKindOfClass:[NSNumber class]]) {
            value = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
        } else if ([type isEqualToString:NSStringFromClass([NSArray class])] && [value isKindOfClass:[NSArray class]]) {
            __block Class entryClass = EntryClassForPropertyInClass(klass, property);
            if (entryClass) {
                NSArray *transformed = [value mappedArrayFromBlock:^id(id value) {
                    return [entryClass buildFromJson:value];
                }];
                if (transformed.count) value = transformed;
                else value = nil;
            }
        } else if ([NSClassFromString(type) isSubclassOfClass:[BSObject class]]) {
            value = [NSClassFromString(type) buildFromJson:value];
        }
        
        if (value == nil || value == [NSNull null]) continue;
        [self setValue:value forKey:property];
    }
}

+ (instancetype)buildFromJson:(NSDictionary *)json {
    Class klass = [self class];
    BSObject *instance = [klass new];
    [instance updateFromJson:json];
    [instance built];
    return instance;
}

- (void)serialize:(NSString *)property to:(NSMutableDictionary *)json {
    Class klass = [self class];
    
    BOOL use = ShouldSerializePropertyInClass(klass, property);
    if (!use) return;
    
    id value = [self valueForKeyPath:property];
    
    if ([value isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = DateFormatterForPropertyInClass(klass, property);
        if (formatter) {
            value = [formatter stringFromDate:value];
        } else {
            value = @([value timeIntervalSince1970]);
        }
    } else if ([value isKindOfClass:[BSObject class]]) {
        value = [value json];
    } else if ([value isKindOfClass:[NSArray class]]) {
        value = [value mappedArrayFromBlock:^id(id value) {
            if ([value isKindOfClass:[BSObject class]]) {
                return [value json];
            } else {
                return value;
            }
        }];
    }
    
    BOOL called = NO;
    id transformed = TransformedValueToJsonForPropertyInClass(klass, property, value, &called);
    if (transformed && called) value = transformed;
    
    BOOL nulls = ShouldSerializeNullsForPropertyInClass(klass, property);
    if (!nulls && (value == nil || value == [NSNull null])) return;
    
    if (value == nil || value == [NSNull null]) value = [NSNull null];
    
    NSString *key = JsonKeyForPropertyInClass(klass, property);
    [json setObject:value forKeyPath:key];
}
- (NSDictionary *)jsonFromWhitelist:(NSArray *)keys {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    NSDictionary *properties = [[self class] writableProperties];
    for (NSString *property in properties) {
        if ([keys containsObject:property]) [self serialize:property to:json];
    }
    return json.count ? [NSDictionary dictionaryWithDictionary:json] : nil;
}
- (NSDictionary *)json {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    NSDictionary *properties = [[self class] writableProperties];
    for (NSString *property in properties) {
        [self serialize:property to:json];
    }
    return json.count ? [NSDictionary dictionaryWithDictionary:json] : nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[self class] buildFromJson:self.json];
}

@end