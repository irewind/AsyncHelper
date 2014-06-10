//
//  NSString+Utils.h
//  SlickFlick
//
//  Created by Raul Andrisan on 8/16/12.
//  Copyright (c) 2012 Curious Quests Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Utils)
- (BOOL)isEmail;
- (BOOL) hasSubString:(NSString *) str;
- (NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
- (NSString *)urlDecodeUsingEncoding:(NSStringEncoding)encoding;
+ (NSString *)formattedDateFromTimestamp:(NSString *)timestamp;
+ (NSString *)formattedDateFromDate:(NSDate*)date;
+ (NSString *)shortDateFromDate:(NSDate *)date;
+ (NSString *)shortDateFromTimestamp:(NSString *)timestamp;
- (BOOL)containsString:(NSString *)string;
- (BOOL)containsString:(NSString *)string
               options:(NSStringCompareOptions) options;
//NSString* AHNSStringF (NSString *format, ...);
-(NSString*)trim;
-(BOOL) isEmpty;
+(NSString *)getUUID;
@end
