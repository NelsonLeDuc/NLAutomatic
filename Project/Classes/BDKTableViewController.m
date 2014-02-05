//
//  BDKTableViewController.m
//  BDKAutomatic
//
//  Created by Ben Kreeger on 2/2/14.
//  Copyright (c) 2014 Ben Kreeger. All rights reserved.
//

#import "BDKTableViewController.h"

#import "BDKMapViewController.h"

#import <BDKAutomatic/BDKAutomatic.h>
#import <BDKAutomatic/BDKAutomaticTrip.h>

@interface BDKTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (weak, nonatomic) BDKAutomatic *automatic;

@property (strong, nonatomic) NSArray *rawTrips;

- (void)tableViewDidPullToRefresh:(UIRefreshControl *)control;
- (void)logoutButtonTapped:(UIBarButtonItem *)sender;

@end

@implementation BDKTableViewController

#pragma mark - Lifecycle

+ (instancetype)viewControllerWithAutomaticAdapter:(BDKAutomatic *)adapter {
    id instance = [self new];
    [instance setAutomatic:adapter];
    return instance;
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.rawTrips = [NSArray array];
    self.title = @"Trips";
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(tableViewDidPullToRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(logoutButtonTapped:)];
    self.navigationItem.leftBarButtonItem = logoutButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.refreshControl beginRefreshing];
    [self tableViewDidPullToRefresh:self.refreshControl];
}

#pragma mark - Properties

- (UITableView *)tableView {
    if (_tableView) return _tableView;
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    return _tableView;
}

#pragma mark - Private methods

- (void)tableViewDidPullToRefresh:(UIRefreshControl *)control {
    [self.automatic getTrips:^(NSError *error, id responseObject) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:responseObject[@"message"]
                                        message:responseObject[@"documentation_url"]
                                       delegate:nil
                              cancelButtonTitle:@"Close"
                              otherButtonTitles:nil, nil] show];
            NSLog(@"Error! %@", responseObject);
            [control endRefreshing];
            return;
        }
        self.rawTrips = responseObject;
        [control endRefreshing];
        
        [self.tableView reloadData];
    }];
}

- (void)logoutButtonTapped:(UIBarButtonItem *)sender {
    if (self.userDidLogout) {
        self.userDidLogout();
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.rawTrips count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    BDKAutomaticTrip *trip = self.rawTrips[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", trip.startTime];
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BDKMapViewController *mapVC = [BDKMapViewController new];
    mapVC.trip = self.rawTrips[indexPath.row];
    [self.navigationController pushViewController:mapVC animated:YES];
}

@end
