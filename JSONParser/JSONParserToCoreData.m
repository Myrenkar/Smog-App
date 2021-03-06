//
//  JSONParserToCoreData.m
//  Smogapp
//
//  Created by Piotr Torczyski on 14/01/16.
//  Copyright © 2016 Piotr Torczyski. All rights reserved.
//

#import "JSONParserToCoreData.h"
#import "Station+CoreDataProperties.h"
#import "Pollution+CoreDataProperties.h"
#import "AppDelegate.h"

@interface JSONParserToCoreData()

@property NSArray *citiesArrayFromRawJSON;
@property NSArray *timeStamps;
@property NSArray *stationArray;
@property NSNumber *timeStamp;
@property NSNumber *longitude;
@property NSNumber *lattitude;
@property NSArray *pollutionsArray;
@property  Station *stations;
@end

@implementation JSONParserToCoreData

- (instancetype)init {
    if (self = [super init]) {
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        self.context = appDelegate.managedObjectContext;
    }
    return self;
}

- (id )sanitizedDictionaryWithJSON:(id)JSON {
    id returnData;
    
    if([JSON isKindOfClass:[NSDictionary class]]){
        
        NSMutableDictionary *mutableJSON = [JSON mutableCopy];
        
        for (NSString *key in mutableJSON.allKeys) {
            if (mutableJSON[key] == [NSNull null]) {
                [mutableJSON removeObjectForKey:key];
            }
        }
        returnData = [mutableJSON copy];
    }
    
    else if([JSON isKindOfClass:[NSArray class]]){
        
        NSMutableDictionary *sanitezJSON ;
        NSMutableArray *mutableJSONArray = [JSON mutableCopy];
        
        for (sanitezJSON in mutableJSONArray) {
            
            for (NSString *key in sanitezJSON.allKeys) {
                if (sanitezJSON[key] == [NSNull null]) {
                    [sanitezJSON removeObjectForKey:key];
                }
            }
            
        }
        returnData = [mutableJSONArray copy];
    }
    else{
        
        NSLog(@"Error in casting response");
    }
    
    return returnData;
}

-(NSArray *)parseCitiesFromJSON:(id)JSON{
    NSArray *cities;
    NSDictionary *sanitizedJSON = [self sanitizedDictionaryWithJSON:JSON];
    NSSet *citySet;
    
    citySet = [NSSet setWithArray:[sanitizedJSON valueForKey:@"citydesc"]];
    cities = [citySet allObjects];
    
    cities = [cities sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return  cities;
}


-(NSArray *)parseLocationFromJSON:(id)JSON{
    
    NSDictionary *sanitizedJSON = [self sanitizedDictionaryWithJSON:JSON];
    NSArray *cityLocations;
    
    NSSet* locations;
    
    locations = [NSSet setWithArray: [sanitizedJSON valueForKey: @"location"]];
    cityLocations =  [locations allObjects];
    
    return cityLocations;
    
}
-(void)saveJSONToCoreData:(id)JSON{
    
    NSDictionary *sanitizedJSON = [self sanitizedDictionaryWithJSON:JSON];
    NSError *error = nil;
    if([JSON isKindOfClass:[NSDictionary class]]){
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        
        Station *station = [NSEntityDescription insertNewObjectForEntityForName:@"Station" inManagedObjectContext:self.context];
        Pollution *pollution = [NSEntityDescription insertNewObjectForEntityForName:@"Pollution" inManagedObjectContext:self.context];
        
        NSMutableDictionary *mutableJSON = [JSON mutableCopy];
        
        for (NSString *key in mutableJSON.allKeys) {
            
            if (sanitizedJSON[@"value"] ==nil) {
                
            }
            else{
                
                
                if (sanitizedJSON[@"aqidesc"] == nil) {
                    pollution.desc = sanitizedJSON[@"caqidesc"];
                }
                else {
                    pollution.desc = sanitizedJSON[@"aqidesc"];
                }
                
                pollution.name = sanitizedJSON[@"parameterdesc"];
                pollution.value = [NSNumber numberWithDouble:[sanitizedJSON[@"value"] integerValue]];
                pollution.timestamp = sanitizedJSON[@"timestamp"];
                pollution.unit = sanitizedJSON[@"unit"];
                
                station.name = sanitizedJSON[@"parameterdesc"];
                station.location = sanitizedJSON[@"location"];
                station.locationdesc = sanitizedJSON[@"locationdesc"];
                station.timestamp = [NSNumber numberWithInt:[sanitizedJSON[@"timestamp"]integerValue]];
                station.longitude = [f numberFromString: sanitizedJSON[@"long"]];
                station.lattitude = [f numberFromString: sanitizedJSON[@"lat"]];
                
                [station addParametersObject:pollution];
            }
        }
    }
    else if([JSON isKindOfClass:[NSArray class]]){
        
        Station *station = [NSEntityDescription insertNewObjectForEntityForName:@"Station" inManagedObjectContext:self.context];
        
        NSMutableDictionary *dictionaryJSON ;
        NSMutableArray *mutableJSONArray = [JSON mutableCopy];
        NSDictionary *firsDictionary = [mutableJSONArray objectAtIndex:1];
        NSNumberFormatter *formater = [[NSNumberFormatter alloc] init];
        formater.numberStyle = NSNumberFormatterCurrencyStyle;
        
        
        station.name = firsDictionary[@"parameterdesc"];
        station.locationdesc = firsDictionary[@"locationdesc"];
        station.longitude =  [NSNumber numberWithDouble:[firsDictionary[@"long"] doubleValue]];
        station.lattitude = [NSNumber numberWithDouble:[firsDictionary[@"lat"] doubleValue]];
        station.location = firsDictionary[@"location"];
        station.timestamp = [NSNumber numberWithInt:[firsDictionary[@"timestamp"]integerValue]];
        
        for (dictionaryJSON in mutableJSONArray) {
            Pollution *pollution = [NSEntityDescription insertNewObjectForEntityForName:@"Pollution" inManagedObjectContext:self.context];
            if (dictionaryJSON[@"value"] == nil) {
                
            }
            else{
                if (dictionaryJSON[@"caqidesc"] == nil) {
                    pollution.desc = dictionaryJSON[@"aqidesc"];
                }
                else {
                    pollution.desc = dictionaryJSON[@"caqidesc"];
                }
                pollution.value = [NSNumber numberWithDouble:[dictionaryJSON[@"value"] integerValue]];
                pollution.timestamp = [NSNumber numberWithInt:[dictionaryJSON[@"timestamp"]integerValue]];
                pollution.name = dictionaryJSON[@"parameterdesc"];
                pollution.unit = dictionaryJSON[@"unit"];
                [station addParametersObject:pollution];
            }
            
        }
        
    }
    
    if (![self.context save:&error]) {
        NSLog(@"Unable to save managed object context for stations.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }
}



-(void)parseStationFromLocationJSON:(id)JSON{
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    
    
    NSMutableArray *mutableJSONArray = [JSON mutableCopy];
    NSDictionary *firsDictionary = [mutableJSONArray objectAtIndex:1];
    
    self.timeStamp = [NSNumber numberWithInt:[firsDictionary[@"timestamp"]integerValue]];
    
    self.longitude = [NSNumber numberWithDouble:[firsDictionary[@"long"] doubleValue]];
    
    self.lattitude = [NSNumber numberWithDouble:[firsDictionary[@"lat"] doubleValue]];
    
    NSPredicate *longitudePredicate = [NSPredicate predicateWithFormat:@"lattitude == %@",self.lattitude];
    NSPredicate *lattitudePredicate = [NSPredicate predicateWithFormat:@"longitude == %@",self.longitude];
    NSPredicate *fetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[lattitudePredicate, longitudePredicate]];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Station"];
    [fetchRequest setPredicate:fetchPredicate];
    
    self.stationArray = [[self.context executeFetchRequest:fetchRequest error:nil] mutableCopy];
  
    
    if(self.stationArray.count == (NSUInteger)nil ){
        [self saveJSONToCoreData:JSON];
    }
    
    else {
        
        NSPredicate *timestampPredicate = [NSPredicate predicateWithFormat:@"timestamp == %@",self.timeStamp];
             NSFetchRequest *pollutionRequest = [[NSFetchRequest alloc] initWithEntityName:@"Pollution"];
        [pollutionRequest setPredicate:timestampPredicate];
        
        self.pollutionsArray = [[self.context executeFetchRequest:pollutionRequest error:nil] mutableCopy];
        NSSet *timestampSet;
        for (Pollution *pol in self.stationArray) {
            timestampSet =[NSSet setWithArray: [self.pollutionsArray valueForKey:@"timestamp"]];
        }
         NSLog(@"Timestamp set for location: %@", timestampSet);
        BOOL isTimeStampInCoreData = NO;
        
        for (NSNumber *timestampNumber in timestampSet) {
            if ([timestampNumber integerValue] == [self.timeStamp integerValue]) {
                isTimeStampInCoreData = YES;
            }
        }
        if( isTimeStampInCoreData ){
            
            return;
        }
        else{
            
            [self saveJSONToCoreData:JSON];
            
        }
        
    }
    
    
}
@end
