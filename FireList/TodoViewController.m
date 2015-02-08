//
//  TodoViewController.m
//  FireList
//
//  Created by Developer on 2/7/15.
//  Copyright (c) 2015 JDare. All rights reserved.
//

#import "TodoViewController.h"
#import "Constants.h"
#import <Firebase/Firebase.h>
#import "EditTodoViewController.h"

#define kCellIdentifier @"todoCell"


@interface TodoViewController () {
    Firebase *fireBase;
    NSMutableArray *todoList;
}
@end

@implementation TodoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSLog(@"Init Firebase");
    // Create a reference to a Firebase location
    fireBase = [[Firebase alloc] initWithUrl: kFirebaseURL];
    fireBase = [fireBase childByAppendingPath:@"todos/"];
    
    todoList = [[NSMutableArray alloc] init];
    
    [[fireBase queryOrderedByKey]
        observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        [todoList removeAllObjects];
        if (![snapshot.value isEqual:[NSNull null]])
        {
        NSDictionary *todos = snapshot.value;
        //NSLog(@"%@", snapshot.value[@"todos"]);
        for (NSString *key in todos) {
            if (key != (id)[NSNull null])
            {
                NSDictionary *todo = [todos objectForKey:key];
                
                NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:[todo[@"created_at"] doubleValue]];

                TodoItem *item = [[TodoItem alloc]initWithText:todo[@"text"] createdAt:createdAt isComplete:[todo[@"complete"] boolValue]];
                item.key = key;
                [todoList addObject:item];
            }
        }
            todoList = [NSMutableArray arrayWithArray:[todoList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSDate *first = [(TodoItem*)obj1 createdAt];
                NSDate *second = [(TodoItem*)obj2 createdAt];
                return [second compare:first];
            }]];
        [self.tableView reloadData];
        }
    }];
    
    self.tableView.allowsSelection = YES;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [todoList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    TodoItem *todo = [todoList objectAtIndex: [indexPath row]];
    // Configure the cell...
    cell.textLabel.text = todo.text;
    
    if (todo.isComplete)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    TodoItem *todo = [todoList objectAtIndex: [indexPath row]];
    todo.isComplete = !todo.isComplete;
    //update it on firebase
    [self saveUpdatedTodoItem:todo];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"EditTodoSegue"]) {
        EditTodoViewController *vc = (EditTodoViewController *)[segue.destinationViewController topViewController];
        vc.delegate = self;
    }
    
    
}

- (void)saveUpdatedTodoItem:(TodoItem *)todo {
    Firebase *todoRef;
    if (todo.key == nil)
    {
        todoRef = [fireBase childByAutoId];
    } else {
        todoRef = [fireBase childByAppendingPath:todo.key];
    }
    [todoRef setValue: [todo asDict]];
}

@end
