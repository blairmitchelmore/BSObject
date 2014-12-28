//
//  BSObjectTests.m
//  BSObjectTests
//
//  Created by Blair Mitchelmore on 12/20/2014.
//  Copyright (c) 2014 Blair Mitchelmore. All rights reserved.
//

#import "BasicObject.h"
#import "AdvancedObject.h"

SpecBegin(InitialSpecs)

describe(@"BasicObject", ^{
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"basic" withExtension:@"json"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    it(@"will build objects", ^{
        BasicObject *test = [BasicObject buildFromJson:dict];
        expect(test.string).to.equal(@"stringValue");
        expect(test.longerKey).to.equal(@"longerKeyValue");
        expect(test.number).to.equal(@1234);
        expect(test.ignored).to.beNil();
        
        
        NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSGregorianCalendar];
        calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        
        NSDateComponents *epochDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitNanosecond fromDate:test.epochDate];
        
        NSLog(@"epochDateComponents: %@", epochDateComponents);
        expect(epochDateComponents.year).to.equal(2014);
        expect(epochDateComponents.month).to.equal(12);
        expect(epochDateComponents.day).to.equal(19);
        expect(epochDateComponents.hour).to.equal(3);
        expect(epochDateComponents.minute).to.equal(20);
        expect(epochDateComponents.second).to.equal(15);
        expect(epochDateComponents.nanosecond).to.equal(0);
        
    });
    
    it(@"will generate json", ^{
        BasicObject *test = [BasicObject buildFromJson:dict];
        NSDictionary *json = test.json;
        NSLog(@"json: %@", json);
        expect(json[@"string"]).to.equal(@"stringValue");
        expect(json[@"longer_key"]).to.equal(@"longerKeyValue");
        expect(json[@"number"]).to.equal(@1234);
        expect(json[@"ignored"]).to.beNil();
        expect(json[@"epoch_date"]).to.equal(@1418959215);
    });
});


describe(@"AdvancedObject", ^{
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"advanced" withExtension:@"json"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    it(@"will build objects", ^{
        AdvancedObject *test = [AdvancedObject buildFromJson:dict];
        BasicObject *first = test.children[0];
        BasicObject *second = test.children[1];
        BasicObject *third = test.children[2];
        expect(test.preset).to.equal(@40392);
        expect(test.skippedOnRead).to.beNil();
        expect(test.skippedOnWrite).to.equal(@"write");
        expect(test.customKey).to.equal(@54321);
        expect(test.nestedKey).to.equal(@90210);
        expect(test.firstNestedChild).to.equal(@30943);
        expect(test.secondNestedChild).to.equal(@20132);
        expect(test.deeplyNestedKey).to.equal(@650432);
        expect(test.transformed).to.equal(@90809);
        expect(test.readNull).to.beNil();
        expect(test.writtenNull).to.beNil();
        expect(test.children.count).to.equal(3);
        expect(first).to.beKindOf([BasicObject class]);
        expect(first.string).to.equal(@"first");
        expect(first.number).to.equal(@1);
        expect(second).to.beKindOf([BasicObject class]);
        expect(second.string).to.equal(@"second");
        expect(second.number).to.equal(@2);
        expect(third).to.beKindOf([BasicObject class]);
        expect(third.string).to.equal(@"third");
        expect(third.number).to.equal(@3);
        
        NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSGregorianCalendar];
        calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        
        NSDateComponents *standardDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitNanosecond fromDate:test.customDate];
        
        NSLog(@"standardDateComponents: %@", standardDateComponents);
        expect(standardDateComponents.year).to.equal(2014);
        expect(standardDateComponents.month).to.equal(12);
        expect(standardDateComponents.day).to.equal(19);
        expect(standardDateComponents.hour).to.equal(3);
        expect(standardDateComponents.minute).to.equal(20);
        expect(standardDateComponents.second).to.equal(15);
        expect(standardDateComponents.nanosecond).to.beCloseToWithin(123000000, 1000);
        
        
    });
    
    it(@"will generate json", ^{
        AdvancedObject *test = [AdvancedObject buildFromJson:dict];
        test.skippedOnRead = @"read";
        test.skippedOnWrite = @"write";
        NSDictionary *json = test.json;
        NSLog(@"json: %@", json);
        expect(json[@"preset"]).to.equal(@40392);
        expect(json[@"nested"][@"value"]).to.equal(@90210);
        expect(json[@"pair"][@"first"]).to.equal(@30943);
        expect(json[@"pair"][@"second"]).to.equal(@20132);
        expect(json[@"deeply"][@"nested"][@"fields"][@"test"]).to.equal(@650432);
        expect(json[@"different_key"]).to.equal(@54321);
        expect(json[@"skipped_on_read"]).to.equal(@"read");
        expect(json[@"transformed"]).to.equal(@"90809");
        expect(json[@"skipped_on_write"]).to.beNil();
        expect(json[@"read_null"]).to.beNil();
        expect(json[@"written_null"]).to.beKindOf([NSNull class]);
        expect(json[@"children"]).to.beKindOf([NSArray class]);
        expect([json[@"children"] count]).to.equal(3);
        expect(json[@"children"][0][@"string"]).to.equal(@"first");
        expect(json[@"children"][0][@"number"]).to.equal(@1);
        expect(json[@"children"][1][@"string"]).to.equal(@"second");
        expect(json[@"children"][1][@"number"]).to.equal(@2);
        expect(json[@"children"][2][@"string"]).to.equal(@"third");
        expect(json[@"children"][2][@"number"]).to.equal(@3);
    });
});

SpecEnd