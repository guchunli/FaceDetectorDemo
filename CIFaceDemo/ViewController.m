//
//  ViewController.m
//  CIFaceDemo
//
//  Created by Yomob on 2018/12/6.
//  Copyright © 2018年 Yomob. All rights reserved.
//

#import "ViewController.h"
#import "CIFaceViewController.h"
#import "AVDynamicViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITableView *tab = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tab.dataSource = self;
    tab.delegate = self;
    [self.view addSubview:tab];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Core Image 静态人脸识别";
    }else if (indexPath.row == 1){
        cell.textLabel.text = @"AVFoundation 动态人脸识别";
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        CIFaceViewController *faceVC = [[CIFaceViewController alloc]init];
        [self.navigationController pushViewController:faceVC animated:YES];
    }else if (indexPath.row == 1){
        AVDynamicViewController *faceVC = [[AVDynamicViewController alloc]init];
        [self.navigationController pushViewController:faceVC animated:YES];
    }
}


@end
