//
//  ViewController.h
//  Smogapp
//
//  Created by Piotr Torczyski on 08/01/16.
//  Copyright © 2016 Piotr Torczyski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *citiesTableView;

@property(nonatomic) NSString *cityNameForRequest;

@end

