//
//  TaskViewController.m
//  91TaoJin
//
//  Created by keyrun on 14-5-7.
//  Copyright (c) 2014年 guomob. All rights reserved.
//

#import "TaskViewController.h"
#import "HeadToolBar.h"
#import "MScrollVIew.h"
#import "LoadingView.h"
#import "MyUserDefault.h"
#import "AsynURLConnection.h"
#import "UIAlertView+NetPrompt.h"
#import "NewJFQCell.h"
#import "SDImageView+SDWebCache.h"
#import "GameGroup.h"
#import "NSString+IsEmply.h"
#import "TBFootView.h"
#import "TaskAppCell.h"
#import "TaskAppSubCell.h"
#import "GarnishedDetailController.h"

#import "YouMiConfig.h"
#import "YouMiPointsManager.h"
#import "YouMiWall.h"
#import "MiidiAdWall.h"
#import "ADCPowerWallViewController.h"
#import "TaoJinScrollView.h"
#import "TablePullToLoadingView.h"
#import "NSString+md5Code.h"
#import "Guise.h"
#import "GarnishedCell.h"
#import "PBOfferWall.h"
#import "PunchBoxAd.h"

#import "GuoMobWallViewController.h"

#import "AdwoOfferWall.h"
#import "QumiConfigTool.h"
#import "QumiOfferWall.h"
#import "TaoJinLabel.h"
#import "NSDate+nowTime.h"

#import "TalkingDataSDK.h"

#import "StatusBar.h"
#import "DMAdView.h"
#import "UIImage+ColorChangeTo.h"
#import "TaoJinButton.h"
#import "NSDate+nowTime.h"

#define TableHeadViewHeight                                     75.0f                              //tableHeadView的高度
#define TableFootViewHeight                                     30.0f                              //tableFootView的高度
#define TableButtonViewHeight                                   58.0f                              //tableButton的高度
#define SignTime                                                100
#define InstallBtnHeight                                        41.0f
#define SeparateLineHeight                                      5.0f

//test
@implementation TaskViewController{
    HeadToolBar *_headToolBar;                              //顶部toolBar
    //    UITableView *_tableView;                                //列表
    TaskTableView *_tableView;
    
    BOOL isFrist;                                           //标识是否第一次获取数据
    BOOL isNeedShowGarnishedView;                           //判断是否需要显示伪装页面
    int timeOutCount;                                       //连接超时次数
    int localPageNumber;                                    //当前请求页的页码数
    int temporaryLocalPageNumner;                           //(临时)当前请求页的页码数
    int serviceCurrentPage;                                 //服务器当前页数
    int serviceMaxNumber;                                   //服务器最大app数量
    int serviceMaxPage;                                     //服务器最大页数
    int cellWithoutGroud;                                   //除app和app任务外的行数
    int appOpenState;                                       //跳转打开app的方式(0为内部打开，1为外部打开)
    
    NSNumber *nowTime;                                      //当前显示该页面的时间
    
    
    NSMutableArray *temporaryJifenAry;                      //临时积分墙数据
    
    
    NSMutableArray *appParticipateAry;                      //已参与的app数据
    NSMutableArray *appUnParticipateAry;                    //未参与的app数据
    NSMutableArray *appFinishAry;                           //已完成的app数据
    
    
    NSMutableArray *temporaryAppAry;                        //临时所有app数据（包括未参与，已参与，已完成）
    NSMutableArray *temporaryAppParticipateAry;             //临时已参与的app数据
    NSMutableArray *temporaryAppUnParticipateAry;           //临时未参与的app数据
    NSMutableArray *temporaryAppFinishAry;                  //临时已完成的app数据
    
    NSMutableArray *localAppAry;                            //存放所有的app数据，包括tasks
    NSMutableArray *temporaryLocalAppAry;                   //临时存放所有的app数据，包括tasks
    
    
    NSMutableArray *insertRowsAry;                          //要插入的subCell
    NSIndexPath *oldIndexPath;                              //上一次点击打开的app详细信息的位置
    NSMutableDictionary *appIsOpenDic;                      //标识当前位置的app是否已经开启
    
    NSString *jfqName;                                      //点击选择的积分墙名称
    GameGroup *installGroup;                                //当前展开要安装的app
    
    dispatch_queue_t queue;                                 //串行队列
    NSDictionary *jifenBody;                                //积分墙的body（用于判断是否需要显示伪装界面）
    NSMutableArray *garnishedAry;                           //伪装界面需要显示的内容
    
    QumiOfferWall *qumiWall;                                //趣米【积分墙】
    
    
    BOOL isJumpToWebApp;                                    //标示是否跳转到app商店
    BOOL isOpenApp;                                         //标示是否打开应用
    
    UIBackgroundTaskIdentifier _bgTask;                     //进入后台任务
    
    NSString *userId;
    
    int selectAppId;                                        //选中的appId
    
    NSString *appUrl ;                                      //选择appurl
    
    BOOL isHadFinishTask;                                   //标识是否有已经完成的任务
    
    NSIndexPath *uploadPhotoPath;                            //记录点击跳转【上传截图】的所在行块
    
    NSMutableDictionary *sectionDic;                         //标识每一块是否有数据
    
    BOOL isFristInit;
    DMAdView *dmAdView;
    int adFailCount ;                                        //广告加载失败次数
    
    UIImageView *topView;
    
    UIView *selectView;
    
    TaskAppCell *oldSelectCell;
    
    NSMutableArray *superApps ;                           // 需要自动链接的app
    int superLinkIndex;
    BOOL isNeedSuperLink;
    NSMutableArray *haveLinkedApps  ;                     // 执行了超链接的apps
}

@synthesize mobisage = _mobisage;
@synthesize isRequesting = _isRequesting;
@synthesize jifenAry = _jifenAry;
@synthesize appAry = _appAry;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)initWithObjects{
    
    localPageNumber = 1;
    isHadFinishTask = NO;
    if(insertRowsAry == nil)
        insertRowsAry = [NSMutableArray array];
    if(appIsOpenDic == nil)
        appIsOpenDic = [NSMutableDictionary dictionary];
    cellWithoutGroud = 0;
    if(sectionDic == nil)
        sectionDic = [@{@"ArrayTag1": [NSNumber numberWithBool:NO], @"ArrayTag2": [NSNumber numberWithBool:NO], @"ArrayTag3": [NSNumber numberWithBool:NO],     @"ArrayTag4": [NSNumber numberWithBool:NO], @"ArrayTag5": [NSNumber numberWithBool:NO]} mutableCopy];
    if(isFrist)
        [self requestToSpecialMisson];
    isFrist = YES;
    
    if (!superApps) {
        superApps =[[NSMutableArray alloc] init];
    }
    superLinkIndex = 0;
    haveLinkedApps = [[NSMutableArray alloc]init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = YES;
    //    queue = dispatch_queue_create("com.91Taojin.TaskViewController", DISPATCH_QUEUE_SERIAL);
    _isRequesting = NO;
    isFrist = NO;
    isFristInit = YES;
    [self initWithObjects];
    //顶部横栏
    _headToolBar = [[HeadToolBar alloc] initWithTitle:KLone backgroundColor:KOrangeColor2_0];
    [self.view addSubview:_headToolBar];
    
    NSLog(@"kmainScreenHeigh = %f",kmainScreenHeigh);
    //列表
    _tableView = [self loadTableViewWithFrame:CGRectMake(0.0f, _headToolBar.frame.origin.y + _headToolBar.frame.size.height, kmainScreenWidth, kmainScreenHeigh - _headToolBar.frame.origin.y - _headToolBar.frame.size.height - kfootViewHeigh - (kBatterHeight))];
    
    [self.view addSubview:_tableView];
    
    //    TablePullToLoadingView *loadingView = [[TablePullToLoadingView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, kTableLoadingViewHeight2_0)];
    //    loadingView.backgroundColor = [UIColor whiteColor];
    //    _tableView.tableFooterView = loadingView;
    //    _tableView.tableFooterView.hidden = YES;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestToSpecialMissonNotification:) name:@"requestToSpecialMisson" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showYouMiAd) name:@"YouMiAd" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterForegroundEvent:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(superLinkApps) name:@"SuperLink" object:nil];
}
-(void)superLinkApps{
    //2.0.1  自动执行回调地址
    if (superLinkIndex!=0) {
        [superApps removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, superLinkIndex)]];
    }
    superLinkIndex =superApps.count ;
    /*
     if (serviceCurrentPage == 1) {
     long long int refreshNowTime =[NSDate getNowTime];
     NSString * nowTimeStr =[NSDate changeTimeWith:[NSString stringWithFormat:@"%lld",refreshNowTime]];
     if ([[MyUserDefault standardUserDefaults]getHaveDoneSuperLinked]) {
     for (NSDictionary* dic in [[MyUserDefault standardUserDefaults] getHaveDoneSuperLinked]) {
     NSString *oldTime =[dic objectForKey:@"<#string#>"]
     }
     }else{
     [self doSuperLink];
     }
     
     
     if ([[MyUserDefault standardUserDefaults] getLastSuperLinkTime]) {
     NSString *oldTimeStr = [[MyUserDefault standardUserDefaults] getLastSuperLinkTime] ;
     
     if (![oldTimeStr isEqualToString:nowTimeStr]) {
     isNeedSuperLink = YES;
     [self doSuperLink];
     
     }
     
     }else{
     isNeedSuperLink = YES;
     [self doSuperLink];
     }
     
     }else{
     if (isNeedSuperLink == YES) {
     [self doSuperLink];
     }
     }
     */
    long long int refreshNowTime =[NSDate getNowTime];
    NSString * nowTimeStr =[NSDate changeTimeWith:[NSString stringWithFormat:@"%lld",refreshNowTime]];
    for (GameGroup *game in superApps) {
        NSString *key =[NSString stringWithFormat:@"%d",game.appId];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:key]) {     //app 之前执行过
            NSString *oldTime =[[NSUserDefaults standardUserDefaults] objectForKey:key];
            if (![oldTime isEqualToString:nowTimeStr]) {
                [self doneSuperLinkedWithUDID:game.udidUrl andWithADUrl:game.adUrl andAPPId:game.appId];
            }
        }else{
            [self doneSuperLinkedWithUDID:game.udidUrl andWithADUrl:game.adUrl andAPPId:game.appId];
        }
    }
    /*
    if (![[MyUserDefault standardUserDefaults] getHaveDoneSuperLinked]) {
        [self doSuperLink];
    }else{
        if (serviceCurrentPage == 1) {
            for (GameGroup *game in superApps) {
                NSString *key = [NSString stringWithFormat:@"%d",game.appId];
                for (NSDictionary *dic in [[MyUserDefault standardUserDefaults] getHaveDoneSuperLinked]) {
                    if ([key isEqualToString:[dic.allKeys objectAtIndex:0]]) {
                        NSString *oldTime = [dic objectForKey:key];
                        if (![oldTime isEqualToString:nowTimeStr]) {
                            isNeedSuperLink =YES ;
                            [self doSuperLink];
                        }
                    }
                }
            }
            
        }else{
            
        }
    }
     */
    
}
-(void)doneSuperLinkedWithUDID:(NSString *)udid andWithADUrl:(NSString *)adUrl andAPPId:(int )appId{
    [self requestToSendUDIDUrlMessage:udid];
    [self requestToSendAdUrlJumpMessage:adUrl];
    long long int time = [NSDate getNowTime];
    NSString *timeStr =[NSDate changeTimeWith:[NSString stringWithFormat:@"%lld",time]];
    NSLog(@"__times_%@",timeStr);
//    [[MyUserDefault standardUserDefaults] setLastSuperLinkTime:timeStr];     //记录上次刷新时间
//    NSDictionary *dic =[[NSDictionary alloc] initWithObjectsAndKeys:timeStr,[NSString stringWithFormat:@"%d",appId], nil];
    [[NSUserDefaults standardUserDefaults] setObject:timeStr forKey:[NSString stringWithFormat:@"%d",appId]];


}
-(void)doSuperLink{
    
    if (superApps.count > 0) {
        for (GameGroup *game in superApps) {
            NSString *udidStr =game.udidUrl;
            NSString *adUrl =game.adUrl;
            NSLog(@" APPS Super Linked");
            [self requestToSendUDIDUrlMessage:udidStr];
            [self requestToSendAdUrlJumpMessage:adUrl];
            
            long long int time = [NSDate getNowTime];
            NSString *timeStr =[NSDate changeTimeWith:[NSString stringWithFormat:@"%lld",time]];
            NSLog(@"__times_%@",timeStr);
            [[MyUserDefault standardUserDefaults] setLastSuperLinkTime:timeStr];     //记录上次刷新时间
            NSDictionary *dic =[[NSDictionary alloc] initWithObjectsAndKeys:timeStr,[NSString stringWithFormat:@"%d",game.appId], nil];
            [haveLinkedApps addObject:dic];
            [[MyUserDefault standardUserDefaults] setObject:timeStr forKey:[NSString stringWithFormat:@"%d",game.appId]];
        }
        
    }
    [[MyUserDefault standardUserDefaults] setHaveDoneSuperLinked:haveLinkedApps];
    
}
-(void)viewWillAppear:(BOOL)animated{
    if (IOS_Version >=7.0) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

-(void)viewDidAppear:(BOOL)animated{
    
}

/**
 *  当登录成功后通知请求积分墙数据
 *
 */
-(void)requestToSpecialMissonNotification:(NSNotification *)notification{
    //    [self requestToSpecialMisson];
    if([[MyUserDefault standardUserDefaults] getIsOpenApp] == YES || isFristInit){
        //        [self requestToSpecialMisson];
        [self initWithObjects];
        [[MyUserDefault standardUserDefaults] setIsOpenApp:NO];
        isFristInit = NO;
    }
}

/*
 *   监听主界面被其他程序切换
 */
- (void)didEnterBackgroundEvent:(NSNotification *)notification {
    UIDevice* device = [UIDevice currentDevice];
    
    BOOL backgroundSupported = NO;
    
    if ([device respondsToSelector:@selector(isMultitaskingSupported)]){
        backgroundSupported = device.multitaskingSupported;
    }
    __block int timeCount = 0;
    [[MyUserDefault standardUserDefaults] setAppSchemes:installGroup.schemes];
    [[MyUserDefault standardUserDefaults] setAppSchemesAppId:[NSString stringWithFormat:@"%d",installGroup.appId] schemes:installGroup.schemes];
    
    NSNumber *schemesTime = [[MyUserDefault standardUserDefaults] getAppSchemesTime:installGroup.schemes];
    if(schemesTime != nil)
        timeCount = [schemesTime intValue];
    if (backgroundSupported && _bgTask == UIBackgroundTaskInvalid){
        UIApplication *app = [UIApplication sharedApplication];
        _bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        }];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Do the work associated with the task.
            int status = [[[MyUserDefault standardUserDefaults] getAppSchemesStatus:installGroup.schemes] intValue];
            NSLog(@"status = %d",status);
            while (app.applicationState == UIApplicationStateBackground && _bgTask != UIBackgroundTaskInvalid && timeCount < SignTime && status == 0){
                [NSThread sleepForTimeInterval:1];
                timeCount ++;
                //每隔一秒就保存一次是因为有可能在玩其他app时内存被回收了，所以只能每隔一秒就保存一次
                [[MyUserDefault standardUserDefaults] setAppSchemesTime:installGroup.schemes time:[NSNumber numberWithInt:timeCount]];
            }
            [app endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
        });
    }
}

/*
 *   监听主界面进入前台
 */
-(void)didEnterForegroundEvent:(NSNotification *)notification{
    
    NSString *schemes = [[MyUserDefault standardUserDefaults] getAppSchemes];
    int timeCount = [[[MyUserDefault standardUserDefaults] getAppSchemesTime:schemes] intValue];
    NSLog(@"timeCount = %d",timeCount);
    int status = [[[MyUserDefault standardUserDefaults] getAppSchemesStatus:installGroup.schemes] intValue];
    NSNumber *signTimeNum = [[MyUserDefault standardUserDefaults] getSignFreshTime];
    int signTime = 30;
    if(signTimeNum != nil)
        signTime = [signTimeNum intValue];
    if(timeCount >= signTime && status == 0){
        NSString *appId = [[MyUserDefault standardUserDefaults] getAppAppIdWithSchemes:schemes];
        [self requestToSendSignType:appId];
    }else{
        [_tableView reloadData];
    }
}

/**
 *  加载列表
 *
 *  @param frame 列表大小
 *
 */
-(TaskTableView *)loadTableViewWithFrame:(CGRect)frame{
    TaskTableView *table = [[TaskTableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    [table setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [table setSeparatorColor:[UIColor whiteColor]];
    table.backgroundColor = [UIColor whiteColor];
    table.delegate = self;
    table.dataSource = self;
    table.delaysContentTouches = YES;
    return table;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    int sctionsCount = 0;
    if([garnishedAry count] > 0){
        sctionsCount ++;
        [sectionDic setObject:[NSNumber numberWithBool:YES] forKey:@"ArrayTag1"];
    }
    if([temporaryJifenAry count] > 0){
        sctionsCount ++;
        [sectionDic setObject:[NSNumber numberWithBool:YES] forKey:@"ArrayTag2"];
    }
    if([temporaryAppUnParticipateAry count] > 0){
        sctionsCount ++;
        [sectionDic setObject:[NSNumber numberWithBool:YES] forKey:@"ArrayTag3"];
    }
    if([temporaryAppParticipateAry count] > 0){
        sctionsCount ++;
        [sectionDic setObject:[NSNumber numberWithBool:YES] forKey:@"ArrayTag4"];
    }
    if([temporaryAppFinishAry count] > 0){
        sctionsCount ++;
        [sectionDic setObject:[NSNumber numberWithBool:YES] forKey:@"ArrayTag5"];
    }
    return sctionsCount;
}

/**
 *  获取数据标识
 *
 *  @param section 所在一块
 *
 */
-(int)getDataIndexWithSection:(NSInteger)section{
    int count = 0;
    int index;
    //    NSLog(@"sectionDic = %@",sectionDic);
    //    NSLog(@"section = %d",section);
    for(index = 1 ; index <= 5 ; index ++){
        BOOL tag = [[sectionDic objectForKey:[NSString stringWithFormat:@"ArrayTag%d",index]] boolValue];
        if(tag){
            count ++;
            if(count == section + 1)
                break;
            else
                continue;
        }
    }
    return index;
}

/**
 *  获取所在块的数据量
 *
 *  @param index 标识
 *
 */
-(int)getDataCountWithIndex:(int)index{
    switch (index) {
        case 1:
            return garnishedAry.count;
            break;
        case 2:
            if (temporaryJifenAry.count % 2 == 1) {
                return temporaryJifenAry.count/2 + 1;
            }else{
                return temporaryJifenAry.count/2;
            }
            break;
        case 3:
            return temporaryAppUnParticipateAry.count;
            break;
        case 4:
            return temporaryAppParticipateAry.count;
            break;
        case 5:
            return temporaryAppFinishAry.count;
            break;
        default:
            return 0;
            break;
    }
}

/**
 *  获取每一块Header的高度
 *
 *  @param index 标识
 *
 */
-(float)getHeaderHeightWithIndex:(int)index{
    switch (index) {
        case 1:
            return 29.0f;
            break;
        case 2:
            return 0.0f;
            break;
        case 3:
        case 4:
        case 5:
            return TableFootViewHeight;
            break;
        default:
            return 0.0f;
            break;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int index = [self getDataIndexWithSection:section];
    return [self getDataCountWithIndex:index];
}

-(float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    int index = [self getDataIndexWithSection:section];
    return [self getHeaderHeightWithIndex:index];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    int index = [self getDataIndexWithSection:section];
    static NSString *FooterIdentifier = @"TipImformationView";
    TBFootView *footView = (TBFootView *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:FooterIdentifier];
    if(footView == nil){
        footView = [[TBFootView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, TableFootViewHeight) titleStr:@""];
    }
    switch (index) {
        case 1:
            footView.titleLab.text = @"最热门任务";
            return footView;
            break;
        case 2:
            return nil;
            break;
        case 3:
            footView.titleLab.text = @"未参与";
            return footView;
            break;
        case 4:
            footView.titleLab.text = @"已参与";
            return footView;
            break;
        case 5:
            footView.titleLab.text = @"已完成";
            return footView;
            break;
        default:
            return nil;
            break;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    int index = [self getDataIndexWithSection:indexPath.section];
    id object;
    if(index == 1){
        static NSString *GarnishedCellIndentifier = @"GarnishedCell";
        GarnishedCell *cell = (GarnishedCell *)[tableView dequeueReusableCellWithIdentifier:GarnishedCellIndentifier];
        if(cell == nil){
            cell = [[GarnishedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GarnishedCellIndentifier];
        }
        [cell showGarnishContent:[garnishedAry objectAtIndex:indexPath.row]];
        return cell;
    }else if(index == 2){
        static NSString *JifenCellIndentifier = @"JiFenCell";
        NewJFQCell *cell = (NewJFQCell *)[tableView dequeueReusableCellWithIdentifier:JifenCellIndentifier];
        if(cell == nil){
            cell = [[NewJFQCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:JifenCellIndentifier];
        }
        [self initShowJiFenWallCell:cell jinFenDataAry:temporaryJifenAry indexPath:indexPath];
        if(indexPath.row == temporaryJifenAry.count/2 - 1){
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0.0, 75.0f, kmainScreenWidth, 0.5)];
            line.backgroundColor = kLineColor2_0;
            [cell.contentView addSubview:line];
        }
        return cell;
    }else if(index == 3){
        object = [temporaryAppUnParticipateAry objectAtIndex:indexPath.row];
    }else if(index == 4){
        object = [temporaryAppParticipateAry objectAtIndex:indexPath.row];
    }else if(index == 5){
        object = [temporaryAppFinishAry objectAtIndex:indexPath.row];
    }
    
    static NSString *Join_Cell = @"AppCellId1";
    static NSString *JoinWithLine_Cell = @"AppCellId2";
    if([object isKindOfClass:[GameGroup class]]){
        GameGroup *group = (GameGroup *)object;
        TaskAppCell *cell;
        if(indexPath.row == 0){
            cell = (TaskAppCell *)[tableView dequeueReusableCellWithIdentifier:Join_Cell];
            if(cell == nil){
                cell = [[TaskAppCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Join_Cell isSeparatedLine:NO cellHeight:TableHeadViewHeight];
            }
        }else{
            cell = (TaskAppCell *)[tableView dequeueReusableCellWithIdentifier:JoinWithLine_Cell];
            if(cell == nil){
                cell = [[TaskAppCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:JoinWithLine_Cell isSeparatedLine:YES cellHeight:TableHeadViewHeight];
            }
        }
        for(UIView *view in cell.contentView.subviews){
            if(view.tag >= 100){
                [view removeFromSuperview];
            }
        }
        [cell setHeadViewByAppGroup:group];
        for (UIView *currentView in cell.subviews)
        {
            if([currentView isKindOfClass:[UIScrollView class]])
            {
                ((UIScrollView *)currentView).delaysContentTouches = NO;
                break;
            }
        }
        if([_tableView isEqualToSelectedIndexPath:indexPath]){
            return [self tableView:tableView expendCell:cell expendIndexPath:indexPath];
        }
        
        return cell;
    }
}

//123
/**
 *  展开时添加任务信息
 *
 *  @param tableView 列表
 *  @param cell      展开的cell
 *  @param indexPath 所在行
 *
 */
- (UITableViewCell *)tableView:(UITableView *)tableView expendCell:(TaskAppCell *)cell expendIndexPath:(NSIndexPath *)indexPath{
    id object;
    int index = [self getDataIndexWithSection:indexPath.section];
    if(index == 1){
        Guise *guise = [garnishedAry objectAtIndex:indexPath.row];
        GarnishedDetailController *garnished = [[GarnishedDetailController alloc] initWithGuise:guise];
        UINavigationController *nc = (UINavigationController*)[UIApplication sharedApplication].keyWindow.rootViewController;
        [nc pushViewController:garnished animated:YES];
    }else if(index == 3){
        object = [temporaryAppUnParticipateAry objectAtIndex:indexPath.row];
    }else if(index == 4){
        object = [temporaryAppParticipateAry objectAtIndex:indexPath.row];
    }else if(index == 5){
        object = [temporaryAppFinishAry objectAtIndex:indexPath.row];
    }
    installGroup = (GameGroup *)object;
    
    float y = TableHeadViewHeight;
    if(indexPath.row > 0){
        y += SeparateLineHeight;
    }
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(Spacing2_0, y, kmainScreenWidth - 2 * Spacing2_0, 0.5f)];
    lineView.backgroundColor = kGrayLineColor2_0;
    lineView.tag = 100;
    [cell.contentView addSubview:lineView];
    
    TaoJinLabel *beanLab;               //可赚金豆值
    TaoJinLabel *infoLab;               //任务信息
    UIView *tapView;                    //底图
    int subCellsCount = installGroup.subCells.count;
    for(int i = 0 ; i < subCellsCount ; i ++){
        NSDictionary *dic = [installGroup.subCells objectAtIndex:i];
        int state = [[dic objectForKey:@"State"] intValue];
        int step = [[dic objectForKey:@"Step"] intValue];
        NSString *beanLabStr = [dic objectForKey:@"GiftBean"];
        UIColor *beanLabColor ;
        UIColor *infoLabColor ;
        if([beanLabStr intValue] > 0 && (state == 1 || state == 3)){
            beanLabStr = [@"+" stringByAppendingString:beanLabStr];
            beanLabColor = KOrangeColor2_0;
            if(step > 10){
                infoLabColor = KOrangeColor2_0;
            }else{
                infoLabColor = KGreenColor2_0;
            }
        }else {
            beanLabStr = @"已完成";
            beanLabColor = KGrayColor2_0;
            infoLabColor = KGrayColor2_0;
        }
        //可赚金豆值
        
        float beanLabY = lineView.frame.origin.y + lineView.frame.size.height + 8.0f;
        if([[dic objectForKey:@"Step"] intValue] == 11){
            beanLabY += 0.0f;
        }
        if(tapView != nil){
            beanLabY = tapView.frame.origin.y + tapView.frame.size.height + 4.0f;
        }
        tapView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, beanLabY , kmainScreenWidth, infoLab.frame.size.height + 6.0f)];
        beanLab = [[TaoJinLabel alloc] initWithFrame:CGRectMake(Spacing2_0, 3.0, 50.0f, 20.0f) text:beanLabStr font:[UIFont boldSystemFontOfSize:11] textColor:beanLabColor textAlignment:NSTextAlignmentRight numberLines:1];
        [beanLab sizeToFit];
        beanLab.frame = CGRectMake(Spacing2_0, 3.0f, 50.0f, beanLab.frame.size.height);
        beanLab.tag = 100;
        [tapView addSubview:beanLab];
        //        [cell.contentView addSubview:beanLab];
        //任务信息
        float infoLabWidth =0 ;
        if (step > 10) {
            infoLabWidth = kmainScreenWidth - beanLab.frame.origin.x - beanLab.frame.size.width - Spacing2_0 - 16.0f -58.0f;
        }else{
            infoLabWidth = kmainScreenWidth - beanLab.frame.origin.x - beanLab.frame.size.width - Spacing2_0 - 16.0f ;
        }
         
        
        infoLab = [[TaoJinLabel alloc] initWithFrame:CGRectMake(beanLab.frame.origin.x + beanLab.frame.size.width + Spacing2_0 + 9.0f, 3.0f, infoLabWidth, 20.0f) text:[dic objectForKey:@"Info"] font:[UIFont boldSystemFontOfSize:11] textColor:infoLabColor textAlignment:NSTextAlignmentLeft numberLines:0];
        
        [infoLab sizeToFit];
        infoLab.frame = CGRectMake(infoLab.frame.origin.x, 3.0f, infoLabWidth, infoLab.frame.size.height);
        infoLab.tag = 100;
        
        //        [cell.contentView addSubview:infoLab];
        tapView.frame = CGRectMake(tapView.frame.origin.x, tapView.frame.origin.y, tapView.frame.size.width, infoLab.frame.size.height + 6.0f);
        if(step > 10){
            UIImageView *photoBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(infoLab.frame.origin.x - 3.0f, 0.0f, infoLab.frame.size.width + 5.0f, tapView.frame.size.height)];
            photoBackgroundView.image = [UIImage createImageWithColor:KLightGrayColor2_0];
            photoBackgroundView.highlightedImage = [UIImage createImageWithColor:kBlockBackground2_0];
            photoBackgroundView.tag = 500;
            [tapView addSubview:photoBackgroundView];
            TaoJinLabel *photoLab;
            if([[dic objectForKey:@"State"] intValue] == 3){
                //审核中
                photoLab = [[TaoJinLabel alloc] initWithFrame:CGRectMake(kmainScreenWidth - 56.0f - Spacing2_0, 0.0f, 56.0f, tapView.frame.size.height) text:@"审核中" font:[UIFont boldSystemFontOfSize:11] textColor:[UIColor whiteColor] textAlignment:NSTextAlignmentCenter numberLines:0];
                photoLab.tag = 600;
                photoLab.backgroundColor = KGrayColor2_0;
                [tapView addSubview:photoLab];
            }else if([[dic objectForKey:@"State"] intValue] == 1){
                //上传截图
                photoLab = [[TaoJinLabel alloc] initWithFrame:CGRectMake(kmainScreenWidth - 56.0f - Spacing2_0, 0.0f, 56.0f, tapView.frame.size.height) text:@"上传截图" font:[UIFont boldSystemFontOfSize:11] textColor:[UIColor whiteColor] textAlignment:NSTextAlignmentCenter numberLines:0];
                photoLab.tag = 600;
                photoLab.backgroundColor = KOrangeColor2_0;
                [tapView addSubview:photoLab];
            }
            
            //            [cell.contentView addSubview:photoBackgroundView];
        }
        tapView.tag = 200 + i;
        [tapView addSubview:infoLab];
        [cell.contentView addSubview:tapView];
        
        if(step > 10 && [[dic objectForKey:@"State"] intValue] == 1){
            //添加点击
            tapView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(uploadPhoto:)];
            [tapView addGestureRecognizer:tapRecognizer];
            UILongPressGestureRecognizer *tapLongRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(uploadPhotoWithLong:)];
            [tapView addGestureRecognizer:tapLongRecognizer];
            
        }
        if(i == 0){
            if([[dic objectForKey:@"Step"] intValue] > 10 ){
                //第一项即为【上传截图】
                isHadFinishTask = YES;
            }else if([[dic objectForKey:@"State"] intValue] == 2){
                //第一个任务为【已成功】
                isHadFinishTask = YES;
            }else {
                isHadFinishTask = NO;
            }
        }
        //        if(i == 0 && [[dic objectForKey:@"State"] intValue] )
    }
    //任务描述
    if(![NSString isEmply:installGroup.appdescription]){
        float y = tapView.frame.origin.y + tapView.frame.size.height + 10.0f;
        tapView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, y, kmainScreenWidth, 0.0f)];
        float infoLabWidth = kmainScreenWidth - beanLab.frame.origin.x - beanLab.frame.size.width - Spacing2_0 - 16.0f;
        infoLab = [[TaoJinLabel alloc] initWithFrame:CGRectMake(beanLab.frame.origin.x + beanLab.frame.size.width + Spacing2_0 + 9.0f, 0.0f, infoLabWidth, 20.0f) text:installGroup.appdescription font:[UIFont boldSystemFontOfSize:11] textColor:KRedColor2_0 textAlignment:NSTextAlignmentLeft numberLines:0];
        [infoLab sizeToFit];
        infoLab.frame = CGRectMake(infoLab.frame.origin.x, 0.0f, infoLabWidth, infoLab.frame.size.height);
        tapView.frame = CGRectMake(tapView.frame.origin.x, tapView.frame.origin.y, tapView.frame.size.width, infoLab.frame.size.height);
        tapView.tag = 100;
        [tapView addSubview:infoLab];
        [cell.contentView addSubview:tapView];
        //        [cell.contentView addSubview:infoLab];
    }
    //安装/打开按钮
    float installBtnY = tapView.frame.origin.y + tapView.frame.size.height + 10.0f;
    TaoJinButton *installBtn = [[TaoJinButton alloc] initWithFrame:CGRectMake(7.0f, installBtnY, kmainScreenWidth - Spacing2_0 * 2, InstallBtnHeight) titleStr:@"安装/打开" titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:16] logoImg:nil backgroundImg:[UIImage createImageWithColor:KGreenColor2_0]];
    NSString *schemes = [NSString stringWithFormat:@"%@://",installGroup.schemes];
    BOOL isOpenSuccess = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:schemes]];
    if((installGroup.missionState == 1 || installGroup.missionState == 2) && installGroup.signIn > 0 && installGroup.signInState == 0 && isOpenSuccess){
        [installBtn setBackgroundImage:[UIImage createImageWithColor:KOrangeColor2_0] forState:UIControlStateNormal];
        [installBtn setBackgroundImage:[UIImage createImageWithColor:KLightOrangeColor2_0] forState:UIControlStateHighlighted];
        [installBtn setTitle:[NSString stringWithFormat:@"签到 +%d金豆",installGroup.signIn] forState:UIControlStateNormal];
    }else{
        [installBtn setBackgroundImage:[UIImage createImageWithColor:KGreenColor2_0] forState:UIControlStateNormal];
        [installBtn setBackgroundImage:[UIImage createImageWithColor:KLightGreenColor2_0] forState:UIControlStateHighlighted];
        [installBtn setTitle:@"安装/打开" forState:UIControlStateNormal];
    }
    [installBtn setBackgroundImage:[UIImage createImageWithColor:KLightGreenColor2_0] forState:UIControlStateHighlighted];
    [installBtn addTarget:self action:@selector(jumpToAppStoreAction:) forControlEvents:UIControlEventTouchUpInside];
    installBtn.tag = 100;
    [cell.contentView addSubview:installBtn];
    
    return cell;
}

- (void)uploadPhotoWithLong:(UILongPressGestureRecognizer *)gesture{
    UIImageView *photoBackgroundView;
    TaoJinLabel *photoLab;
    for(UIView *view in gesture.view.subviews){
        if(view.tag == 500){
            photoBackgroundView = (UIImageView *)view;
            [photoBackgroundView setHighlighted:YES];
        }else if(view.tag == 600){
            photoLab = (TaoJinLabel *)view;
            photoLab.backgroundColor = KLightOrangeColor2_0;
        }
    }
    if(gesture.state == UIGestureRecognizerStateEnded){
        if(isHadFinishTask){
            selectView = gesture.view;
            NSDictionary *dic = [installGroup.subCells objectAtIndex:selectView.tag - 200];
            NSString *phoneTaskInfo = [dic objectForKey:@"Info1"];
            //可以上传截图
            UploadViewController *uploadView = [[UploadViewController alloc] init];
            uploadView.delegate = self;
            TaskPhoto *taskPhoto = [[TaskPhoto alloc] initWithMissionDes:phoneTaskInfo appId:installGroup.appId commentUrl:installGroup.appUrl gold:[[dic objectForKey:@"GiftBean"] intValue] imageAry:[dic objectForKey:@"Pic"] step:[[dic objectForKey:@"Step"] intValue] isAppStorePL:[[dic objectForKey:@"Is_pl"] intValue] andImgs:[[dic objectForKey:@"Pic_num"] intValue] andTip:[dic objectForKey:@"Info2"]];
            uploadView.taskPhoto = taskPhoto;
            UINavigationController *nc = (UINavigationController*)[UIApplication sharedApplication].keyWindow.rootViewController;
            [nc presentViewController:uploadView animated:YES completion:^{
                [photoBackgroundView setHighlighted:NO];
                [photoLab setBackgroundColor:KOrangeColor2_0];
            }];
        }else{
            [StatusBar showTipMessageWithStatus:@"请先完成首个任务再参与截图任务" andImage:[UIImage imageNamed:@"laba.png"] andTipIsBottom:YES];
            double delayInSeconds = 0.2;
            dispatch_time_t delayInNanoSeconds = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_queue_t concurrentQueue = dispatch_get_main_queue();
            dispatch_after(delayInNanoSeconds, concurrentQueue, ^(void){
                [photoBackgroundView setHighlighted:NO];
                [photoLab setBackgroundColor:KOrangeColor2_0];
            });
        }
    }
}

- (void)uploadPhoto:(UITapGestureRecognizer *)gesture{
    UIImageView *photoBackgroundView;
    TaoJinLabel *photoLab;
    for(UIView *view in gesture.view.subviews){
        if(view.tag == 500){
            photoBackgroundView = (UIImageView *)view;
            [photoBackgroundView setHighlighted:YES];
        }else if(view.tag == 600){
            photoLab = (TaoJinLabel *)view;
            photoLab.backgroundColor = KLightOrangeColor2_0;
        }
    }
    if(gesture.state == UIGestureRecognizerStateEnded){
        if(isHadFinishTask){
            selectView = gesture.view;
            NSDictionary *dic = [installGroup.subCells objectAtIndex:selectView.tag - 200];
            NSString *phoneTaskInfo = [dic objectForKey:@"Info1"];
            //可以上传截图
            UploadViewController *uploadView = [[UploadViewController alloc] init];
            uploadView.delegate = self;
            TaskPhoto *taskPhoto = [[TaskPhoto alloc] initWithMissionDes:phoneTaskInfo appId:installGroup.appId commentUrl:installGroup.appUrl gold:[[dic objectForKey:@"GiftBean"] intValue] imageAry:[dic objectForKey:@"Pic"] step:[[dic objectForKey:@"Step"] intValue] isAppStorePL:[[dic objectForKey:@"Is_pl"] intValue] andImgs:[[dic objectForKey:@"Pic_num"] intValue] andTip:[dic objectForKey:@"Info2"]];
            uploadView.taskPhoto = taskPhoto;
            UINavigationController *nc = (UINavigationController*)[UIApplication sharedApplication].keyWindow.rootViewController;
            [nc presentViewController:uploadView animated:YES completion:^{
                [photoBackgroundView setHighlighted:NO];
                [photoLab setBackgroundColor:KOrangeColor2_0];
            }];
        }else{
            [StatusBar showTipMessageWithStatus:@"请先完成首个任务再参与截图任务" andImage:[UIImage imageNamed:@"laba.png"] andTipIsBottom:YES];
            double delayInSeconds = 0.2;
            dispatch_time_t delayInNanoSeconds = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_queue_t concurrentQueue = dispatch_get_main_queue();
            dispatch_after(delayInNanoSeconds, concurrentQueue, ^(void){
                [photoBackgroundView setHighlighted:NO];
                [photoLab setBackgroundColor:KOrangeColor2_0];
            });
        }
    }
}

//返回展开之后的cell的高度
- (CGFloat)tableView:(UITableView *)tableView extendedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float height = 8.5f;
    BOOL isUpload =NO;
    if(indexPath.row > 0)
        height += SeparateLineHeight;
    for(NSDictionary *dic in installGroup.subCells){
        height += [self getCellHighWithStr:[dic objectForKey:@"Info"] step:[dic objectForKey:@"Step"]] ;
        if ([[dic objectForKey:@"Step"] intValue] >10) {
            isUpload =YES;
        }
    }
    if(![NSString isEmply:installGroup.appdescription]){
        height += [self getCellHighWithStr:installGroup.appdescription step:@"0"];
    }
    if (isUpload) {
        if (![NSString isEmply:installGroup.appdescription]) {
            return TableHeadViewHeight + height + InstallBtnHeight + 10.0f +6.0f;
        }else{
        return TableHeadViewHeight + height + InstallBtnHeight + 10.0f +6.0f;
        }
    }else{
     return TableHeadViewHeight + height + InstallBtnHeight + 10.0f + 6.0f;
    }
}

/**
 *  点击【安装/打开】按钮事件
 *
 */
-(void)jumpToAppStoreAction:(id)sender{
    //    [self requestToSendSignType:[NSString stringWithFormat:@"%d",installGroup.appId]];
    //测试
    //    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"clashofclans://"]];
    //    [self sendDownStatus:installGroup];
    
    BOOL isOpenSuccess = NO;
    if(![NSString isEmply:installGroup.schemes]){
        //如果本地有安装该app
        NSString *schemes = [NSString stringWithFormat:@"%@://",installGroup.schemes];
        isOpenSuccess = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:schemes]];
        if(isOpenSuccess){
            //打开成功
            //判断是否完成第一个任务，如果完成，且该app是属于【可签到】且签到状态为【未签到】，开始本地计时
            NSMutableArray *subCells = installGroup.subCells;
            if(subCells.count > 0){
                NSDictionary *dic = [subCells objectAtIndex:0];
                int state = [[dic objectForKey:@"State"] intValue];
                if(state == 2 && installGroup.signInState == 0){
                    [[MyUserDefault standardUserDefaults] setIsOpenApp:YES];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundEvent:) name:UIApplicationDidEnterBackgroundNotification object:nil];
                }
            }
            
        }else{
            //打开失败，一般出现于下载该app后本地手动删除了
            [self jumpeToAppDownloadPageWithOpenState:appOpenState];
            [self requestToSendAdUrlJumpMessage:installGroup.adUrl];
            [self requestToSendUDIDUrlMessage:installGroup.udidUrl];
        }
    }else{
        [self jumpeToAppDownloadPageWithOpenState:appOpenState];
        [self requestToSendAdUrlJumpMessage:installGroup.adUrl];
        [self requestToSendUDIDUrlMessage:installGroup.udidUrl];
    }
}

/**
 *  app下载的跳转方式
 *
 *  @param openState 打开方式
 */
-(void)jumpeToAppDownloadPageWithOpenState:(int)openState{
    if(openState == 1){
        //外部打开
        NSString *urlStr = installGroup.appUrl;
        if (![installGroup.appUrl hasPrefix:@"http"]) {
            //该路径不一定是app store的下载地址，有可能是广告主的中间地址
            urlStr = [NSString stringWithFormat:@"http://%@",installGroup.appUrl];
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
        
    }else{
        //内部打开
        NSArray *ids = [installGroup.appUrl componentsSeparatedByString:@"/id"];
        if(ids.count > 1){
            NSString *stringOne = [ids objectAtIndex:1];
            NSArray *arrayOne = [stringOne componentsSeparatedByString:@"?"];
            NSString *identifier = [arrayOne objectAtIndex:0];
            [self openWithIdentifier:identifier andGame:installGroup];
        }else{
            NSString *urlStr = installGroup.appUrl;
            if (![installGroup.appUrl hasPrefix:@"http"]) {
                urlStr = [NSString stringWithFormat:@"http://%@",urlStr];
            }
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
        }
    }
    [self sendDownStatus:installGroup];
}

/**
 *  发送app下载统计请求
 *
 *  @param game app对象
 */
-(void)sendDownStatus:(GameGroup *)game{
    NSString *sid = [[MyUserDefault standardUserDefaults] getSid];
    NSDictionary *dic = @{@"sid": sid, @"Tid":[NSNumber numberWithInt:game.appId], @"Status":@"0"};
    [self requestToAppdown:dic];
}

/**
 *  发送app下载统计
 *
 */
-(void)requestToAppdown:(NSDictionary *)dic{
    NSString *urlStr = [NSString stringWithFormat:kUrlPre,kOnlineWeb,@"GoldWashingUI",@"Appdown"];
    NSLog(@"发送app下载统计【url】= %@",dic);
    [AsynURLConnection requestWithURL:urlStr dataDic:dic timeOut:httpTimeout success:^(NSData *data) {
        NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"发送app下载统计【response】= %@",dataDic);
    } fail:^(NSError *error) {
        NSLog(@"发送app下载统计【error】= %@",error);
    }];
}

/**
 *  请求广告主的地址
 */
-(void)requestToSendAdUrlJumpMessage:(NSString *)adUrl{
    NSLog(@"请求广告主的地址【url】= %@",adUrl);
    if(![NSString isEmply:adUrl]){
        NSURLRequest *request =[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:adUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:httpTimeout];
        NSURLConnection *connection =[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
        [connection start];
        
        /*
         [AsynURLConnection requestWithURL:adUrl dataDic:nil timeOut:httpTimeout success:^(NSData *data) {
         NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
         NSLog(@"请求广告主的地址【response】= %@",dataDic);
         } fail:^(NSError *error) {
         NSLog(@"请求广告主的地址【error】= %@",error);
         if(error.code == -1002){
         NSLog(@"请求广告主的地址格式不对");
         }
         }];
         */
    }
    
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSLog(@"发送UDID信息成功 message = %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"发送UDID信息失败 error = %@" ,error.description);
}
/**
 *  请求发送UDID信息
 */
-(void)requestToSendUDIDUrlMessage:(NSString *)UDIDUrl{
    NSLog(@"请求发送UDID信息【url】= %@",UDIDUrl);
    if (![NSString isEmply:UDIDUrl]) {         // 发送UDID信息使用get 传参 （UDID信息写在了地址里面）
        NSURLRequest *request =[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:UDIDUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:httpTimeout];
        NSURLConnection *connection =[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
        [connection start];
        
    }
    /*
     if(![NSString isEmply:UDIDUrl]){
     [AsynURLConnection requestWithURL:UDIDUrl dataDic:nil timeOut:httpTimeout success:^(NSData *data) {
     NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
     NSString *errStr =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
     NSLog(@"请求发送UDID信息【response】= %@",errStr);
     } fail:^(NSError *error) {
     NSLog(@"请求发送UDID信息【error】= %@",error);
     if(error.code == -1002){
     NSLog(@"请求发送UDID信息的地址格式不对");
     }
     }];
     }
     */
}


-(void)openWithIdentifier:(NSString *)string andGame:(GameGroup*)game{
    [self sendDownStatus:game];
    SKStoreProductViewController *spv = [[SKStoreProductViewController alloc]init];
    spv.delegate = self;
    [self presentViewController:spv animated:YES completion:nil];
    NSDictionary* dic = [NSDictionary dictionaryWithObject:string forKey:SKStoreProductParameterITunesItemIdentifier];
    [spv loadProductWithParameters:dic completionBlock:^(BOOL result, NSError *error){
        if (result) {
            
        }
    }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    id object;
    int index = [self getDataIndexWithSection:indexPath.section];
    if(index == 1){
        Guise *guise = [garnishedAry objectAtIndex:indexPath.row];
        GarnishedDetailController *garnished = [[GarnishedDetailController alloc] initWithGuise:guise];
        UINavigationController *nc = (UINavigationController*)[UIApplication sharedApplication].keyWindow.rootViewController;
        [nc pushViewController:garnished animated:YES];
    }else if(index == 3){
        object = [temporaryAppUnParticipateAry objectAtIndex:indexPath.row];
    }else if(index == 4){
        object = [temporaryAppParticipateAry objectAtIndex:indexPath.row];
    }else if(index == 5){
        object = [temporaryAppFinishAry objectAtIndex:indexPath.row];
    }
    installGroup = (GameGroup *)object;
    
    //若选择的cell是已经展开的，则收缩
    if ([_tableView isEqualToSelectedIndexPath:indexPath]) {
        [_tableView shrinkCellWithAnimated:YES];
    }
    //展开
    else{
        [_tableView extendCellAtIndexPath:indexPath animated:YES goToTop:YES];
    }
    
    //    oldSelectCell = (TaskAppCell *)[tableView cellForRowAtIndexPath:indexPath];
    /*
     double delayInSeconds = 0.05;
     if([object isKindOfClass:[NSMutableDictionary class]] || [object isKindOfClass:[NSString class]]){
     //点击任务
     if([object isKindOfClass:[NSMutableDictionary class]]){
     NSDictionary *dic = (NSDictionary *)object;
     NSString *phoneTaskInfo = [dic objectForKey:@"Info1"];
     if([NSString isEmply:phoneTaskInfo]){
     //如果没有上传截图的任务描述，直接收缩列表
     if(index == 3){
     if([temporaryAppUnParticipateAry count] > 0){
     [temporaryAppUnParticipateAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count)];
     }
     }else if(index == 4){
     if([temporaryAppParticipateAry count] > 0){
     [temporaryAppParticipateAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count )];
     }
     }else if(index == 5){
     [temporaryAppFinishAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count)];
     }
     if(insertRowsAry.count > 0){
     [tableView deleteRowsAtIndexPaths:insertRowsAry withRowAnimation:UITableViewRowAnimationTop];
     [insertRowsAry removeAllObjects];
     [appIsOpenDic setObject:[NSNumber numberWithBool:NO] forKey:[NSString stringWithFormat:@"%d_%d",oldIndexPath.section, oldIndexPath.row]];
     cellWithoutGroud = 0;
     }
     }else{
     //如果有上传截图的任务描述
     int state = [[dic objectForKey:@"State"] intValue];
     if(state == 1){
     if(isHadFinishTask){
     //如果该APP有完成其中某一项任务，跳转下一个界面
     //记录点击的所在行
     uploadPhotoPath = indexPath;
     UploadViewController *uploadView = [[UploadViewController alloc] init];
     uploadView.delegate = self;
     TaskPhoto *taskPhoto = [[TaskPhoto alloc] initWithMissionDes:phoneTaskInfo appId:selectAppId commentUrl:appUrl gold:[[dic objectForKey:@"GiftBean"] intValue] imageAry:[dic objectForKey:@"Pic"] step:[[dic objectForKey:@"Step"] intValue] isAppStorePL:[[dic objectForKey:@"Is_pl"] intValue] andImgs:[[dic objectForKey:@"Pic_num"] intValue] andTip:[dic objectForKey:@"Info2"]];
     uploadView.taskPhoto = taskPhoto;
     UINavigationController *nc = (UINavigationController*)[UIApplication sharedApplication].keyWindow.rootViewController;
     //                        [nc pushViewController:uploadView animated:YES];
     [nc presentViewController:uploadView animated:YES completion:^{
     
     }];
     }else{
     //该app没有完成其中任何一项任务，弹出提示
     [StatusBar showTipMessageWithStatus:@"请先完成首个任务再参与截图任务" andImage:[UIImage imageNamed:@"laba.png"] andTipIsBottom:YES];
     }
     }
     }
     }else{
     if(index == 3){
     if([temporaryAppUnParticipateAry count] > 0){
     [temporaryAppUnParticipateAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count)];
     }
     }else if(index == 4){
     if([temporaryAppParticipateAry count] > 0){
     [temporaryAppParticipateAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count )];
     }
     }else if(index == 5){
     [temporaryAppFinishAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count)];
     }
     [tableView deleteRowsAtIndexPaths:insertRowsAry withRowAnimation:UITableViewRowAnimationTop];
     [insertRowsAry removeAllObjects];
     [appIsOpenDic setObject:[NSNumber numberWithBool:NO] forKey:[NSString stringWithFormat:@"%d_%d",oldIndexPath.section, oldIndexPath.row]];
     cellWithoutGroud = 0;
     }
     
     }else if([object isKindOfClass:[GameGroup class]]){
     installGroup = (GameGroup *)object;
     selectAppId = installGroup.appId;
     appUrl =installGroup.appUrl;
     BOOL isOpen = [[appIsOpenDic objectForKey:[NSString stringWithFormat:@"%d_%d",oldIndexPath.section, oldIndexPath.row]] boolValue];
     if(isOpen && indexPath.section == oldIndexPath.section && indexPath.row == oldIndexPath.row){
     //所点击的app的当前状态是开启的，这次需要关闭
     isHadFinishTask = NO;
     if(index == 3){
     if([temporaryAppUnParticipateAry count] > 0){
     [temporaryAppUnParticipateAry removeObjectsInRange:NSMakeRange(indexPath.row + 1, insertRowsAry.count)];
     }
     }else if(index == 4){
     if([temporaryAppParticipateAry count] > 0){
     [temporaryAppParticipateAry removeObjectsInRange:NSMakeRange(indexPath.row + 1, insertRowsAry.count )];
     }
     }else if(index == 5){
     [temporaryAppFinishAry removeObjectsInRange:NSMakeRange(indexPath.row + 1, insertRowsAry.count)];
     }
     if(insertRowsAry.count > 0){
     [tableView deleteRowsAtIndexPaths:insertRowsAry withRowAnimation:UITableViewRowAnimationNone];
     //                [UIView transitionWithView:tableView
     //                                  duration:.4f
     //                                   options:UIViewAnimationOptionCurveEaseIn
     //                                animations:^{
     //                                    [tableView deleteRowsAtIndexPaths:insertRowsAry withRowAnimation:UITableViewRowAnimationAutomatic];
     //                                } completion:^(BOOL finished) {
     //
     //                                }];
     [insertRowsAry removeAllObjects];
     [appIsOpenDic setObject:[NSNumber numberWithBool:NO] forKey:[NSString stringWithFormat:@"%d_%d",oldIndexPath.section, oldIndexPath.row]];
     cellWithoutGroud = 0;
     }
     }else{
     //所点击的app的当前状态是关闭的，这次需要开启
     if(oldIndexPath != nil){
     //之前已经打开过app,且该app没有关闭，需要先关闭
     delayInSeconds = 0.0;
     isHadFinishTask = NO;
     int oldIndex = [self getDataIndexWithSection:oldIndexPath.section];
     if(isOpen){
     if(oldIndex == 3){
     if([temporaryAppUnParticipateAry count] > 0){
     [temporaryAppUnParticipateAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count )];
     }
     }else if(oldIndex == 4){
     if([temporaryAppParticipateAry count] > 0){
     [temporaryAppParticipateAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count )];
     }
     }else if(oldIndex == 5){
     [temporaryAppFinishAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count )];
     }
     if(insertRowsAry.count > 0){
     NSIndexPath *insertPath = [insertRowsAry objectAtIndex:0];
     if(insertPath.section == indexPath.section){
     if(insertPath.row > indexPath.row)
     [tableView deleteRowsAtIndexPaths:insertRowsAry withRowAnimation:UITableViewRowAnimationFade];
     else
     [tableView deleteRowsAtIndexPaths:insertRowsAry withRowAnimation:UITableViewRowAnimationAutomatic];
     }else{
     [tableView deleteRowsAtIndexPaths:insertRowsAry withRowAnimation:UITableViewRowAnimationFade];
     }
     if(indexPath.section == oldIndexPath.section && indexPath.row > oldIndexPath.row){
     indexPath = [NSIndexPath indexPathForRow:indexPath.row - insertRowsAry.count inSection:indexPath.section];
     }
     [appIsOpenDic setObject:[NSNumber numberWithBool:NO] forKey:[NSString stringWithFormat:@"%d_%d",oldIndexPath.section, oldIndexPath.row]];
     cellWithoutGroud = 0;
     [insertRowsAry removeAllObjects];
     }
     }
     }
     GameGroup *group ;
     NSDictionary *dic ;
     if(installGroup.subCells .count > 0){
     dic = [installGroup.subCells objectAtIndex:0];
     }
     if([[dic objectForKey:@"Step"] intValue] > 10){
     isHadFinishTask = YES;
     }
     if(index == 3){
     if([temporaryAppUnParticipateAry count] > 0){
     group = [temporaryAppUnParticipateAry objectAtIndex:indexPath.row];
     [temporaryAppUnParticipateAry insertObjects:group.subCells atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexPath.row + 1, group.subCells.count)]];
     //如果有任务签到描述要求
     if(![NSString isEmply:group.appdescription]){
     [temporaryAppUnParticipateAry insertObject:group.appdescription atIndex:indexPath.row + 1 + group.subCells.count + cellWithoutGroud];
     cellWithoutGroud ++;
     }
     [temporaryAppUnParticipateAry insertObject:[UIButton buttonWithType:UIButtonTypeCustom] atIndex:indexPath.row + 1 + group.subCells.count + cellWithoutGroud];
     cellWithoutGroud ++;
     }
     }else if(index == 4){
     if([temporaryAppParticipateAry count] > 0){
     group = [temporaryAppParticipateAry objectAtIndex:indexPath.row];
     [temporaryAppParticipateAry insertObjects:group.subCells atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexPath.row + 1, group.subCells.count)]];
     //如果有任务签到描述要求
     if(![NSString isEmply:group.appdescription]){
     [temporaryAppParticipateAry insertObject:group.appdescription atIndex:indexPath.row + 1 + group.subCells.count + cellWithoutGroud];
     cellWithoutGroud ++;
     }
     [temporaryAppParticipateAry insertObject:[UIButton buttonWithType:UIButtonTypeCustom] atIndex:indexPath.row + 1 + group.subCells.count + cellWithoutGroud];
     cellWithoutGroud ++;
     }
     }else if(index == 5){
     group = [temporaryAppFinishAry objectAtIndex:indexPath.row];
     [temporaryAppFinishAry insertObjects:group.subCells atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexPath.row + 1, group.subCells.count)]];
     //如果有任务签到描述要求
     if(![NSString isEmply:group.appdescription]){
     [temporaryAppFinishAry insertObject:group.appdescription atIndex:indexPath.row + 1 + group.subCells.count + cellWithoutGroud];
     cellWithoutGroud ++;
     }
     [temporaryAppFinishAry insertObject:[UIButton buttonWithType:UIButtonTypeCustom] atIndex:indexPath.row + 1 + group.subCells.count + cellWithoutGroud];
     cellWithoutGroud ++;
     }
     NSMutableArray *localInsertRowsAry = [NSMutableArray array];
     for(int i = indexPath.row + 1 ; i <= indexPath.row + group.subCells.count + cellWithoutGroud; i ++){
     NSIndexPath *localIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
     [localInsertRowsAry addObject:localIndexPath];
     }
     [appIsOpenDic setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"%d_%d",indexPath.section, indexPath.row]];
     //            NSLog(@"delayInSeconds = %f",delayInSeconds);
     dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
     dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
     // code to be executed on the main queue after delay
     if(insertRowsAry.count == 0){
     [tableView insertRowsAtIndexPaths:localInsertRowsAry withRowAnimation:UITableViewRowAnimationBottom];
     //                    [UIView transitionWithView:tableView
     //                                      duration:.4f
     //                                       options:UIViewAnimationOptionCurveEaseIn
     //                                    animations:^{
     //                                        [tableView insertRowsAtIndexPaths:localInsertRowsAry withRowAnimation:UITableViewRowAnimationAutomatic];
     //                                    } completion:^(BOOL finished) {
     //
     //                                    }];
     
     
     NSIndexPath *localIndexPath = [NSIndexPath indexPathForRow:indexPath.row + localInsertRowsAry.count inSection:indexPath.section];
     [UIView animateWithDuration:0.4f animations:^{
     [tableView scrollToRowAtIndexPath:localIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
     }completion:^(BOOL finished) {
     if(finished){
     insertRowsAry = localInsertRowsAry;
     }
     }];
     }
     });
     }
     oldIndexPath = indexPath;
     }
     */
}



/**
 *  上传截图成功的回调
 */
-(void)uploadImageSuccess{
    //    NSDictionary *dic = [installGroup.subCells objectAtIndex:uploadPhotoPath.row - oldIndexPath.row - 1];
    NSDictionary *dic = [installGroup.subCells objectAtIndex:selectView.tag - 200];
    NSMutableDictionary *mDic = [dic mutableCopy];
    [mDic setObject:[NSNumber numberWithInt:3] forKey:@"State"];
    [installGroup.subCells replaceObjectAtIndex:selectView.tag - 200 withObject:mDic];
    
    int index = [self getDataIndexWithSection:uploadPhotoPath.section];
    if(index == 3){
        [temporaryAppUnParticipateAry replaceObjectAtIndex:uploadPhotoPath.row  withObject:[installGroup.subCells objectAtIndex:selectView.tag - 200]];
    }else if(index == 4){
        [temporaryAppParticipateAry replaceObjectAtIndex:uploadPhotoPath.row  withObject:[installGroup.subCells objectAtIndex:selectView.tag - 200]];
    }
    [_tableView reloadData];
    //    [_tableView reloadRowsAtIndexPaths:@[uploadPhotoPath] withRowAnimation:UITableViewRowAnimationNone];
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    id object ;
    int index = [self getDataIndexWithSection:indexPath.section];
    switch (index) {
        case 1:
            return 80.0f;
            break;
        case 2:
            return 75.0f;
            break;
        case 3:
            object = [temporaryAppUnParticipateAry objectAtIndex:indexPath.row];
            break;
        case 4:
            object = [temporaryAppParticipateAry objectAtIndex:indexPath.row];
            break;
        case 5:
            object = [temporaryAppFinishAry objectAtIndex:indexPath.row];
            break;
        default:
            break;
    }
    if([object isKindOfClass:[GameGroup class]]){
        if([_tableView isEqualToSelectedIndexPath:indexPath])
        {
            return [self tableView:tableView extendedHeightForRowAtIndexPath:indexPath];
        }
        if(indexPath.row == 0)
            return TableHeadViewHeight;
        else
            return TableHeadViewHeight + SeparateLineHeight;
    }else if([object isKindOfClass:[NSDictionary class]]){
        NSDictionary *subCellAry = (NSDictionary *)object;
        id localObject ;
        if(index == 3){
            if([temporaryAppUnParticipateAry count] > 0){
                localObject = [temporaryAppUnParticipateAry objectAtIndex:indexPath.row - 1];
            }
        }else if(index == 4){
            if([temporaryAppParticipateAry count] > 0){
                localObject = [temporaryAppParticipateAry objectAtIndex:indexPath.row - 1];
            }
        }else if(index == 5){
            localObject = [temporaryAppFinishAry objectAtIndex:indexPath.row - 1];
        }
        
        BOOL isFristDic = NO;
        if([localObject isKindOfClass:[GameGroup class]]){
            isFristDic = YES;
        }
        //测试
        return [self getCellHighWithStr:[subCellAry objectForKey:@"Info"] step:[subCellAry objectForKey:@"Step"]];
    }else if([object isKindOfClass:[NSString class]]){
        NSString *description = (NSString *)object;
        return [self getCellHighWithStr:description step:@"0"] -5.0f;
    }else if([object isKindOfClass:[UIButton class]]){
        return TableButtonViewHeight;
    }else{
        return 0.0;
    }
}

/**
 *  计算Cell的实际高度
 *
 *  @param dic cell需要显示的内容数据
 *
 */
-(float)getCellHighWithStr:(NSString *)str step:(NSString *)step{
    UIFont *font = [UIFont boldSystemFontOfSize:11];
    float width = 0.0f;
    float height = 0.5f;
    if([step isEqualToString:@"11"])
        height += 0.0;
    int stepValue = [step intValue];
    if(stepValue > 10)
        width = 0.0f;
    CGSize size ;
    if (stepValue > 10) {
        size = [str sizeWithFont:font constrainedToSize:CGSizeMake(kmainScreenWidth - 57.0f - Spacing2_0 - 16.0f - width -58.0f, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
    }else{
        size = [str sizeWithFont:font constrainedToSize:CGSizeMake(kmainScreenWidth - 57.0f - Spacing2_0 - 16.0f - width , MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
    }
	 
    return size.height + 10.0f + height;
}

/**
 *  初始化积分墙的单独块
 *
 *  @param cell          所属的cell
 *  @param jinFenDataAry 积分墙的数据
 *  @param indexPath     位置
 */
-(void)initShowJiFenWallCell:(NewJFQCell *)cell jinFenDataAry:(NSArray *)jinFenDataAry indexPath:(NSIndexPath *)indexPath{
    NSDictionary *dicLeft = [jinFenDataAry objectAtIndex:indexPath.row *2];
    
    cell.leftJFQ = [[JFQClass alloc] initWithDictionary:dicLeft];
    cell.isDouble = NO;
    [cell loadWithCellContent];
    [cell.leftImage setImageWithURL:[NSURL URLWithString:cell.leftJFQ.icon] refreshCache:NO needSetViewContentMode:false needBgColor:false placeholderImage:[UIImage imageNamed:@"appIcon.png"]];
    //    NSLog(@"cell.leftView.subviews.count = %d",cell.leftView.subviews.count);
    //    UIView * view = [cell.leftView viewWithTag:kJfqLeftTag];
    UIButton *leftButton = cell.leftButton;
    cell.leftButton.tag = indexPath.row * 2;
    //    NSLog(@"__jfq_Index_ %d %@ %d",indexPath.row,dicLeft,leftButton.tag);
    [leftButton addTarget:self action:@selector(showTipAction:) forControlEvents:UIControlEventTouchUpInside];
    if(jinFenDataAry.count %2 == 0 || (jinFenDataAry.count%2 == 1 && indexPath.row < jinFenDataAry.count/2)){
        NSDictionary* dicRight = [jinFenDataAry objectAtIndex:indexPath.row * 2 + 1];
        cell.rightJFQ = [[JFQClass alloc] initWithDictionary:dicRight];
        cell.isDouble = YES;
        [cell loadWithCellContent];
        [cell.rightImage setImageWithURL:[NSURL URLWithString:cell.rightJFQ.icon] refreshCache:NO needSetViewContentMode:false needBgColor:false placeholderImage:[UIImage imageNamed:@"appIcon.png"]];
        UIButton *rightButton = cell.rightButton;
        rightButton.tag = indexPath.row * 2 + 1;
        [rightButton addTarget:self action:@selector(showTipAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    float y_float = _tableView.contentOffset.y;
    if (y_float < 0)
        return;
    
    if(temporaryAppAry.count != 0 && temporaryLocalPageNumner < serviceMaxPage && _tableView.tableFooterView.tag != 10){
        CGPoint offset = scrollView.contentOffset;
        CGRect bounds = scrollView.bounds;
        CGSize size = scrollView.contentSize;
        UIEdgeInsets inset = scrollView.contentInset;
        float y = offset.y + bounds.size.height - inset.bottom;
        float h = size.height;
        if(y > h - 1) {
            TablePullToLoadingView *loadingView = [[TablePullToLoadingView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, kTableLoadingViewHeight2_0 + 5.0f)];
            //            loadingView.backgroundColor = [UIColor whiteColor];
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, SeparateLineHeight)];
            lineView.backgroundColor = kBlockBackground2_0;
            [loadingView addSubview:lineView];
            _tableView.tableFooterView = loadingView;
            _tableView.tableFooterView.tag = 10;
            [self requestToApp];
        }/*else{
          UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, kTableLoadingViewHeight2_0)];
          footerView.backgroundColor = kBlockBackground2_0;
          UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, SeparateLineHeight)];
          lineView.backgroundColor = kBlockBackground2_0;
          [footerView addSubview:lineView];
          _tableView.tableFooterView = footerView;
          _tableView.tableFooterView.tag = 11;
          }
          */
    }
}


/**
 *  点击积分墙响应事件
 *
 */
#define kTitle                                              @"奖励来之不易，请仔细阅读"
#define kOneContent                                         @"1.按要求完成淘金任务后，请返回91淘金领取金豆"
#define kTwoContent                                         @"2.若体验后未及时赠送金豆，请多次或隔天体验"
#define kThreeContent                                       @"3.首次安装才有奖励，各频道的相同应用只奖励一次"
#define kFourContent                                        @"4.获取的金豆奖励，可在“我的淘金-收支明细”查看"
#define kTip                                                @"不再提示"
#define kOk                                                 @"好的，我知道了"

-(void)showTipAction:(UIButton *)button{
    
    NSDictionary *dic = [temporaryJifenAry objectAtIndex:button.tag];
    jfqName = [dic objectForKey:@"name"];
    
    UIImage* tipImage = [UIImage imageNamed:@"nockeck.png"];
    UIImage* tipHighImage = [UIImage imageNamed:@"ischeck.png"];
    UIImage* bgImage = [UIImage imageNamed:@"tmalert.png"];
    TMAlertView* alert = [[TMAlertView alloc]initWithTitle:kTitle andOneTip:kOneContent andTwoTip:kTwoContent andThreeTip:kThreeContent andFourTip:kFourContent andTipContent:kTip andTipImage:tipImage andTipHighlightImage:tipHighImage andOkContent:kOk andBGImageL:bgImage jifenName:jfqName];
    alert.TMAlertDelegate = self;
    NSNumber *JFQIsCheck = [[MyUserDefault standardUserDefaults] getJFQIsCheck];
    if ([JFQIsCheck integerValue] == 0) {
        alert.isChecked = NO;
        [alert show];
    }else if ([JFQIsCheck integerValue] == 1){
        alert.isChecked = YES;
        [self showJFQ:jfqName];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    if([alertView isKindOfClass:[TMAlertView class]]){
        TMAlertView *alert = (TMAlertView *)alertView;
        [self showJFQ:alert.jfqCheckMark];
    }
    else{
        if(alertView.tag == kTimeOutTag){
            //重新请求获取积分墙
            [UIAlertView resetNetAlertNil];
            [self requestToSpecialMisson];
        }else if(alertView.tag == kTimeOutTag + 1){
            //重新请求获取app
            [UIAlertView resetNetAlertNil];
            [self requestToApp];
        }
    }
    
}

-(void)onClickedTMAlerViewButton{
    [self showJFQ:jfqName];
}


/**
 *  跳转到相应的积分墙
 *
 *  @param jfqName 积分墙的名称
 */
-(void)showJFQ:(NSString *)jfqNameStr{
    userId = [[MyUserDefault standardUserDefaults] getUserId];
    UIApplication *application = [UIApplication sharedApplication];
    NSString *sid = [[MyUserDefault standardUserDefaults] getSid];
    NSDictionary *dic;
    if ([jfqNameStr isEqualToString:kYouMiName]) {
        // 接入有米积分墙
        [YouMiConfig launchWithAppID:kYouMiId appSecret:kYouMiKey];
        [YouMiConfig setUserID:userId];
        [YouMiPointsManager enable];
        [YouMiConfig setUseInAppStore:NO];  //设置跳转方式为 外部跳入app store
        [YouMiWall enable];
        [YouMiConfig setFullScreenWindow:application.keyWindow];
        [YouMiWall showOffers:YES didShowBlock:^{
        }
              didDismissBlock:^{}];
        dic = @{@"sid": sid, @"name": @"youmi_1"};
    }else if ([jfqNameStr isEqualToString:kDianRuName]) {
        // 点入积分墙
        //        [DianRuAdWall beforehandAdWallWithDianRuAppKey:kDianRuKey];
        [TalkingDataSDK initWithAppId:kDianRuKey andChannelId:@"91taojin"];
        [DianRuAdWall initAdWallWithDianRuAdWallDelegate:self];
        [DianRuAdWall showAdWall:self];
        
        dic = @{@"sid": sid, @"name": @"dianru_1"};
    }else if ([jfqNameStr isEqualToString:kDuoMengName]) {
        // 多盟积分墙
        DMOfferWallViewController* dmView = [[DMOfferWallViewController alloc]initWithPublisherID:kDuoMengKey andUserID:userId];
        dmView.delegate =self;
        [dmView presentOfferWall];
        dic = @{@"sid": sid, @"name": @"duomeng_1"};
    }else if ([jfqNameStr isEqualToString:kYJFName]) {
        // 易积分积分墙
        [YJFUserMessage shareInstance].yjfAppKey = kYJFKey;
        [YJFUserMessage shareInstance].yjfUserAppId = kYJFAppID;
        [YJFUserMessage shareInstance].yjfUserDevId = kYJFDevID;
        [YJFUserMessage shareInstance].yjfChannel = @"91taojin";
        [YJFUserMessage shareInstance].yjfCoop_info = userId;
        YJFInitServer* initData = [[YJFInitServer alloc]init];
        [initData getInitEscoreData];
        YJFIntegralWall* wall = [[YJFIntegralWall alloc]init];
        [self presentViewController:wall animated:YES completion:nil];
        dic = @{@"sid": sid, @"name":@"yijifen_1"};
    }else if ([jfqNameStr isEqualToString:kLiMeiName]) {
        // 力美
        /*
         immobView* imView =[[immobView alloc]initWithAdUnitID:kLiMeiKey];
         imView.UserAttribute = [NSMutableDictionary dictionaryWithObjectsAndKeys:userId,@"accountname", nil];
         imView.delegate = self;
         [imView immobViewRequest];
         [application.keyWindow.rootViewController.view addSubview:imView];
         [imView immobViewDisplay];
         */
        immobView *imView =[[immobView alloc] initWithAdUnitId:kLiMeiKey adUnitType:offerWall rootViewController:self userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:userId,@"accountname", nil]];
        imView.UserAttribute = [NSMutableDictionary dictionaryWithObjectsAndKeys:userId,@"accountname", nil];
        [imView immobViewRequest];
        [application.keyWindow.rootViewController.view addSubview:imView];
        
        dic = @{@"sid": sid, @"name":@"limei_1"};
    }else if ([jfqNameStr isEqualToString:kWanPuName]) {
        // 万普
        [AppConnect getConnect:kWPKey pid:@"91taojin" userID:userId];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConnectSuccess:) name:WAPS_CONNECT_SUCCESS object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOfferClosed:) name:WAPS_OFFER_CLOSED object:nil];
        [AppConnect showOffers: application.keyWindow.rootViewController];
        dic = @{@"sid": sid, @"name":@"wanpu_1"};
    }else if ([jfqNameStr isEqualToString:kMiDiName]) {
        // 米迪
        [MiidiManager setAppPublisher:kMiDiId withAppSecret:kMiDiKey];
        [MiidiAdWall showAppOffers:self withDelegate:self];
        [MiidiAdWall setUserParam:userId];
        
        dic = @{@"sid": sid, @"name":@"midi_1"};
    }else if ([jfqNameStr isEqualToString:kAiPuName]) {
        //爱普积分墙
        [ADCPowerWallViewController showPowerWallViewFromViewController:self
                                                                 siteId:kSiteID
                                                                siteKey:kSiteKEY
                                                                mediaId:kMediaID
                                                         userIdentifier:userId
                                                             useSandBox:NO];
        dic = @{@"sid": sid, @"name":@"aipu_1"};
    }else if ([jfqNameStr isEqualToString:kAiDeName]) {
        // 艾德积分墙
        
        if(_mobisage == nil){
            _mobisage = [[MobiSageOfferWallViewController alloc] initWithPublisherID:kAiDeKey];
            _mobisage.delegate = self;
        }
        [_mobisage setUserID:userId];
        _mobisage.disableStoreKit =YES;
        [_mobisage presentOfferWall];
        dic = @{@"sid": sid, @"name":@"aide_1"};
        
    }else if ([jfqNameStr isEqualToString:kChuKongName]){
        //        done    触控
        [PunchBoxAd startSession:kChuKongKey];    //触控
        [PunchBoxAd setUserInfo:userId];
        [[PBOfferWall sharedOfferWall] loadOfferWall:[PBADRequest request]];
        [[PBOfferWall sharedOfferWall] showOfferWallWithScale:0.9f];
        dic = @{@"sid": sid, @"name":@"chukong_1"};
        
    }else if ([jfqNameStr isEqualToString:kZhiMengName]){
        // done   指盟
        /*
         [ZhiMengAdconfig requestZhiMengConnect:kZhiMengKey userId:userId];
         [ZhiMengPointsManger enableZhiMengWall];
         ZhiMengWall *wall= [[ZhiMengWall alloc] init];
         [wall showOfferWall:self viewPosition:YES];
         dic = @{@"sid": sid, @"name":@"zhimeng_1"};
         */
        
    }else if ([jfqNameStr isEqualToString:kAnWoName]){
        //安沃
        NSArray *arr =[NSArray arrayWithObject:userId];
        AdwoOWSetKeywords(arr);
        BOOL result =AdwoOWPresentOfferWall(kAnWoKey, self);
        if (result) {
            NSLog(@"  安沃  成功");
        }else{
            enum ADWO_OFFER_WALL_ERRORCODE errCode = AdwoOWFetchLatestErrorCode();
            NSLog(@"Initialization error, because %d", errCode);
        }
        dic = @{@"sid": sid, @"name":@"anwo_1"};
    }else if ([jfqNameStr isEqualToString:kJuPengName]){
        // 巨朋
        /*
         [JupengWall checkWallEnable:^(NSError* error,BOOL wallEnable)
         {
         if(error == nil){
         NSString *warning = [NSString stringWithFormat:@"积分墙状态%d ",wallEnable];
         [JupengWall setServerUserID:userId];
         [JupengConfig launchWithAppID:kJuPengID withAppSecret:kJuPengKey];
         [JupengWall showOffers:self didShowBlock:^{
         
         } didDismissBlock:^{
         
         }];
         NSLog(@"jupeng%@",warning);
         
         }
         }];
         dic = @{@"sid": sid, @"name":@"jupeng_1"};
         */
        
    }else if ([jfqNameStr isEqualToString:kMoPanName]){
        //           done  磨盘
        /*
         moPanWall =[[MopanAdWall alloc] initWithMopan:kMoPanID withAppSecret:kMoPanKey];
         [moPanWall setCustomUserID:userId];
         moPanWall.rootViewController =self;
         //        wall.delegate =self;
         [moPanWall showAppOffers];
         dic = @{@"sid": sid, @"name":@"mopan_1"};
         */
        
    }else if ([jfqNameStr isEqualToString:kQuMiName]){
        // done  趣米
        [QumiConfigTool startWithAPPID:kQuMiID secretKey:kQuMiKey appChannel:1000];
        qumiWall =[[QumiOfferWall alloc] initwithPointUserID:userId];
        qumiWall.rootViewController =self;
        qumiWall.isHiddenStatusBar =NO;
        [qumiWall autoGetPoints:NO];
        [qumiWall presentQumiOfferWall];
        dic = @{@"sid": sid, @"name":@"qumi_1"};
        
    }else if ([jfqNameStr isEqualToString:kDianLeName]){
        /*
         [DianJoySDK requestDianJoySession:kDianLeKey withUserID:userId];
         [DianJoySDK showDianOffersWallWithViewController:self];
         dic = @{@"sid": sid, @"name":@"dianle_1"};
         */
    }
    else if ([jfqNameStr isEqualToString:kGuoMengName]){     //企业版 2.1.0新增果盟积分墙
        GuoMobWallViewController *guomengWall =[[GuoMobWallViewController alloc]initWithId:kGuoMengKey];
        guomengWall.OtherID = userId ;
        guomengWall.isStatusBarHidden =NO;
        [guomengWall pushGuoMobWall:YES Hscreen:NO];
        dic = @{@"sid": sid ,@"name":@"guomeng"};
    }
    
    [self requestToSumJFQClick:dic];
}

/**
 *  请求统计积分墙的点击次数
 *
 *  @param dic 请求参数
 */

-(void)requestToSumJFQClick:(NSDictionary *)dic{
    NSString *urlStr = [NSString stringWithFormat:kUrlPre,kOnlineWeb,@"GoldWashingUI",@"jfqClick"];
    NSLog(@"统计点击积分墙的次数【urlStr】 = %@",urlStr);
    [AsynURLConnection requestWithURL:urlStr dataDic:dic timeOut:httpTimeout success:^(NSData *data) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"统计点击积分墙的次数【response】 = %@",dataDic);
            dispatch_async(dispatch_get_main_queue(), ^{
                
            });
        });
    }fail:^(NSError *error) {
        NSLog(@"-----统计点击积分墙的次数【error】 = %@ -----",error);
    }];
}

/**
 *  请求获取积分墙
 */
-(void)requestToSpecialMisson{
    if(_jifenAry == nil || _jifenAry.count == 0 || (appParticipateAry.count == 0 && appUnParticipateAry.count == 0 && appFinishAry.count == 0)){

            [[LoadingView showLoadingView] actViewStartAnimation];
        
    }
    _isRequesting = YES;
    NSString *urlStr = [NSString stringWithFormat:kUrlPre,kOnlineWeb,@"GoldWashingUI",@"SpecalMission"];
    NSString *sid = [[MyUserDefault standardUserDefaults] getSid];
    NSDictionary *dic = @{@"sid": sid };
    NSLog(@"获取积分墙【urlStr】 = %@",urlStr);
    NSLog(@"获取积分墙【request】 = %@",dic);
    [AsynURLConnection requestWithURL:urlStr dataDic:dic timeOut:httpTimeout success:^(NSData *data) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"获取积分墙【response】 = %@",dataDic);
            timeOutCount = 0;
            jifenBody = [dataDic objectForKey:@"body"];
            //设置【免责声明】开关  ————> 活动中心
            [[MyUserDefault standardUserDefaults] setIsNeedDutyView:[jifenBody objectForKey:@"Mz"]];
            //设置【活动中心】开关
            [[MyUserDefault standardUserDefaults] setIsNeedActivityView:[jifenBody objectForKey:@"Hd"]];
            //获取是否需要显示伪装界面
            isNeedShowGarnishedView = [self judgeIsNeedToShowGarnishedView:jifenBody];
            if([dataDic objectForKey:@"jf"] != nil){
                if(_jifenAry == nil){
                    _jifenAry = [[NSMutableArray alloc] initWithArray:[dataDic objectForKey:@"jf"]];
                }else{
                    [_jifenAry removeAllObjects];
                    NSMutableArray *localJiFenAry = [dataDic objectForKey:@"jf"];
                    [_jifenAry insertObjects:localJiFenAry atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, localJiFenAry.count)]];
                }
                
                if(temporaryJifenAry == nil){
                    temporaryJifenAry = [[NSMutableArray alloc] initWithArray:_jifenAry];
                }else{
                    [temporaryJifenAry removeAllObjects];
                    [temporaryJifenAry insertObjects:_jifenAry atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _jifenAry.count)]];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestToApp];
            });
        });
    } fail:^(NSError *error) {
        NSLog(@"获取积分墙【error】 = %@",error);
        if(error.code == timeOutErrorCode){
            //连接超时
            if(timeOutCount < 2){
                timeOutCount ++;
                [self requestToSpecialMisson];
            }else{
                timeOutCount = 0;
                _isRequesting = NO;
                [[LoadingView showLoadingView] actViewStopAnimation];
                [self showTimeoutAlertView:kTimeOutTag];
            }
        }
    }];
}

/**
 *  判断是否需要显示伪装界面
 *
 *  @param dic 服务器返回的body结构数据
 */
#define AD                                          @"Ad"
#define DC                                          @"Dc"
#define FL                                          @"Fl"
#define QD                                          @"Qd"
#define SD                                          @"Sd"
#define XT                                          @"Xt"
#define jindou                                      @"+3000"
#define markTypeNum                                 1
-(BOOL)judgeIsNeedToShowGarnishedView:(NSDictionary *)dic{
    BOOL isNeedToShow = NO;
    if(garnishedAry == nil){
        garnishedAry = [[NSMutableArray alloc] init];
    }else{
        [garnishedAry removeAllObjects];
    }
    
    NSNumber *adNum = [dic objectForKey:AD];
    if(adNum != nil && [adNum intValue] == markTypeNum){
        isNeedToShow = YES;
        Guise *guise = [[Guise alloc] initWithImage:[UIImage imageNamed:@"ad"] titleStr:@"网购返利" subTitleStr:@"淘宝购物，赚取金豆奖励" subContentStr:@"通过91淘金购买淘宝店中任何产品，待商品确认收货后即可领取3000金豆奖励。" jindouCountStr:jindou urlStr:@"http://www.taobao.com/?91taojin" btnStr:@"我要购物"];
        [garnishedAry addObject:guise];
    }
    
    NSNumber *dcNum = [dic objectForKey:DC];
    if(dcNum != nil && [dcNum intValue] == markTypeNum){
        isNeedToShow = YES;
        Guise *guise = [[Guise alloc] initWithImage:[UIImage imageNamed:@"dc"] titleStr:@"问卷调查" subTitleStr:@"参与各种问卷调查，赚金豆奖励" subContentStr:@"参与91淘金每日问卷调查，简单填写，即可赚取3000金豆奖励，每日都有新问卷哦，请及时参与。" jindouCountStr:jindou urlStr:@"http://www.sojump.com/jq/3628635.aspx" btnStr:@"我要参与"];
        [garnishedAry addObject:guise];
    }
    
    NSNumber *flNum = [dic objectForKey:FL];
    if(flNum != nil && [flNum intValue] == markTypeNum){
        isNeedToShow = YES;
        Guise *guise = [[Guise alloc] initWithImage:[UIImage imageNamed:@"fl"] titleStr:@"欣赏广告" subTitleStr:@"看最新潮流广告，赚金豆奖励" subContentStr:@"看广告也能赚金豆?是的\n每天可看一次广告,停留5秒后，即可赚取3000金豆奖励，连续7天欣赏广告，赚取的金豆会更多。" jindouCountStr:jindou urlStr:@"http://www.91taojin.com.cn/ios_ad.html" btnStr:@"我要看广告"];
        [garnishedAry addObject:guise];
    }
    
    NSNumber *qdNum = [dic objectForKey:QD];
    if(qdNum != nil && [qdNum intValue] == markTypeNum){
        isNeedToShow = YES;
        Guise *guise = [[Guise alloc] initWithImage:[UIImage imageNamed:@"qd"] titleStr:@"经营学徒" subTitleStr:@"收徒弟，教徒弟，带徒弟一起赚金豆" subContentStr:@"想赚更多的金豆？经营学徒无疑是最佳方式。\n招学徒，如果学徒赚取更多金豆，他的身价就会上升，你也可以相应赚取更多金豆奖励；但是如果学徒不给力的，他的身价就会一直不动，想要把你的金豆回到账上，只能靠系统收回。" jindouCountStr:jindou urlStr:@"" btnStr:@"我要收徒"];
        [garnishedAry addObject:guise];
    }
    
    NSNumber *sdNum = [dic objectForKey:SD];
    if(sdNum != nil && [sdNum intValue] == markTypeNum){
        isNeedToShow = YES;
        Guise *guise = [[Guise alloc] initWithImage:[UIImage imageNamed:@"sd"] titleStr:@"每日签到" subTitleStr:@"每日签到赚取金豆奖励，连续签到奖励更多" subContentStr:@"点击我要签到，完成每日签到任务，获取3000金豆！" jindouCountStr:jindou urlStr:@"" btnStr:@"我要签到"];
        [garnishedAry addObject:guise];
    }
    
    NSNumber *xtNum = [dic objectForKey:XT];
    if(xtNum != nil && [xtNum intValue] == markTypeNum){
        isNeedToShow = YES;
        Guise *guise = [[Guise alloc] initWithImage:[UIImage imageNamed:@"xt"] titleStr:@"晒单有奖" subTitleStr:@"晒晒兑换的奖品，赚取金豆奖励" subContentStr:@"把兑换过的奖品，拍照并分享到微博、微信、QQ空间等网站，并@91淘金，一经确认将奖励3000金豆。" jindouCountStr:jindou urlStr:@"http://www.qzone.qq.com" btnStr:@"我要晒单"];
        [garnishedAry addObject:guise];
    }
    return isNeedToShow;
}


-(NSUInteger )getCurrentSectionWithIndex:(int)index{
    int count = -1;
    for(int i = 1; i <= index; i ++){
        BOOL tag = [[sectionDic objectForKey:[NSString stringWithFormat:@"ArrayTag%d",i]] boolValue];
        if(tag)
            count ++;
    }
    return count;
}

/**
 *  请求获取App数据
 */
-(void)requestToApp{
    _isRequesting = YES;
    if (![[LoadingView showLoadingView] actViewIsAnimation]) {
            [[LoadingView showLoadingView] actViewStartAnimation];
        
    }
    NSString *urlStr = [NSString stringWithFormat:kUrlPre,kOnlineWeb,@"GoldWashingUI",@"GetApps1"];
    NSString *page = [NSString stringWithFormat:@"%d",localPageNumber];
    NSString *sid = [[MyUserDefault standardUserDefaults] getSid];
    NSDictionary *dic = @{@"PageNum": page, @"Join": @"0", @"sid":sid};
    NSLog(@"获取App【urlStr】 = %@",urlStr);
    [AsynURLConnection requestWithURL:urlStr dataDic:dic timeOut:httpTimeout success:^(NSData *data) {
        
        //        double delayInSeconds = 0.2;
        //        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        //        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            timeOutCount = 0;
            NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            NSLog(@"获取App【response】 = %@",dataDic);
            NSDictionary *body = [dataDic objectForKey:@"body"];
            NSArray *apps = [body objectForKey:@"Apps"];
            appOpenState = [[body objectForKey:@"AppOpen"] integerValue];
            serviceMaxNumber = [[body objectForKey:@"MaxNum"] integerValue];
            serviceCurrentPage = [[body objectForKey:@"CurPage"] integerValue];
            serviceMaxPage = [[body objectForKey:@"MaxPage"] integerValue];
            
            //            double delayInSeconds = 0.2;
            //            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            //            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            dispatch_async(dispatch_get_main_queue(), ^{
                //                _tableView.tableFooterView.hidden = YES;
                UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, kTableLoadingViewHeight2_0)];
                footerView.backgroundColor = [UIColor whiteColor];
                
                
                _tableView.tableFooterView = footerView;
                _tableView.tableFooterView.tag = 11;
                
                if(dataDic == nil || serviceCurrentPage != localPageNumber){
                    [[LoadingView showLoadingView] actViewStopAnimation];
                    return ;
                }
                if(localPageNumber == 1){
                    int index = [self getDataIndexWithSection:oldIndexPath.section];
                    if(insertRowsAry.count > 0){
                        if(index == 3){
                            [temporaryAppUnParticipateAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count)];
                        }else if(index == 4){
                            [temporaryAppParticipateAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count)];
                        }else if(index == 5){
                            [temporaryAppFinishAry removeObjectsInRange:NSMakeRange(oldIndexPath.row + 1, insertRowsAry.count)];
                        }
                        [_tableView beginUpdates];
                        [_tableView deleteRowsAtIndexPaths:insertRowsAry withRowAnimation:UITableViewRowAnimationFade];
                        [_tableView endUpdates];
                        [insertRowsAry removeAllObjects];
                        oldIndexPath = nil;
                        cellWithoutGroud = 0;
                    }
                    [_appAry removeAllObjects];
                    [localAppAry removeAllObjects];
                    [appUnParticipateAry removeAllObjects];
                    [appParticipateAry removeAllObjects];
                    [appFinishAry removeAllObjects];
                }
                
                dispatch_queue_t queue1 = dispatch_queue_create("SendMessageViewController", DISPATCH_QUEUE_PRIORITY_DEFAULT);;
                dispatch_barrier_async(queue1, ^{
                    if(_appAry == nil){
                        _appAry = [[NSMutableArray alloc] initWithArray:[self reinitAppAryObjects:apps]];
                        localAppAry = [[NSMutableArray alloc] initWithArray:_appAry];
                        
                        appParticipateAry = [NSMutableArray array];
                        appUnParticipateAry = [NSMutableArray array];
                        appFinishAry = [NSMutableArray array];
                        for(int i = 0 ; i < _appAry.count; i ++){
                            GameGroup *group = [_appAry objectAtIndex:i];
                            if(group.missionState == 0 || group.missionState == 3){
                                [appUnParticipateAry addObject:group];
                            }else if(group.missionState == 1){
                                [appParticipateAry addObject:group];
                            }else if(group.missionState == 2){
                                [appFinishAry addObject:group];
                            }
                            //2.0.1
                            if (group.superLink == 1){
                                [superApps addObject:group];
                            }
                        }
                    }else{
                        int oldAppAryCount = _appAry.count;
                        [_appAry insertObjects:[self reinitAppAryObjects:apps] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_appAry.count, apps.count)]];
                        [localAppAry insertObjects:[self reinitAppAryObjects:apps] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(localAppAry.count, apps.count)]];
                        for(int i = oldAppAryCount ; i < _appAry.count; i ++){
                            GameGroup *group = [_appAry objectAtIndex:i];
                            if(group.missionState == 0 || group.missionState == 3){
                                [appUnParticipateAry addObject:group];
                            }else if(group.missionState == 1){
                                [appParticipateAry addObject:group];
                            }else if(group.missionState == 2){
                                [appFinishAry addObject:group];
                            }
                            if (group.superLink == 1){
                                [superApps addObject:group];
                            }
                        }
                    }
                    
                    if(temporaryAppAry == nil){
                        temporaryAppAry = [[NSMutableArray alloc] initWithArray:_appAry];
                    }else{
                        [temporaryAppAry removeAllObjects];
                        [temporaryAppAry insertObjects:_appAry atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _appAry.count)]];
                    }
                    
                    
                    //插入位置
                    NSMutableArray *paths = [[NSMutableArray alloc] init];
                    if(localPageNumber == 1){
                        if(temporaryAppUnParticipateAry == nil){
                            temporaryAppUnParticipateAry = [[NSMutableArray alloc] initWithArray:appUnParticipateAry];
                        }else{
                            [temporaryAppUnParticipateAry removeAllObjects];
                            [temporaryAppUnParticipateAry insertObjects:appUnParticipateAry atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, appUnParticipateAry.count)]];
                        }
                    }else{
                        if(temporaryAppUnParticipateAry.count != appUnParticipateAry.count){
                            [sectionDic setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"ArrayTag3"]];
                            NSUInteger section = [self getCurrentSectionWithIndex:3];
                            int insertRowCount = 0;
                            if(oldIndexPath.section == section){
                                insertRowCount = insertRowsAry.count;
                            }
                            for (int i = temporaryAppUnParticipateAry.count - insertRowCount; i < appUnParticipateAry.count; i++) {
                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i + insertRowCount  inSection:section];
                                [paths addObject:indexPath];
                                [temporaryAppUnParticipateAry insertObject:[appUnParticipateAry objectAtIndex:i] atIndex:temporaryAppUnParticipateAry.count];
                            }
                        }
                    }
                    
                    if(localPageNumber == 1){
                        if(temporaryAppParticipateAry == nil){
                            temporaryAppParticipateAry = [[NSMutableArray alloc] initWithArray:appParticipateAry];
                        }else{
                            [temporaryAppParticipateAry removeAllObjects];
                            [temporaryAppParticipateAry insertObjects:appParticipateAry atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, appParticipateAry.count)]];
                        }
                    }else{
                        if(temporaryAppParticipateAry.count != appParticipateAry.count){
                            [sectionDic setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"ArrayTag4"]];
                            NSUInteger section = [self getCurrentSectionWithIndex:4];
                            int insertRowCount = 0;
                            if(oldIndexPath.section == section){
                                insertRowCount = insertRowsAry.count;
                            }
                            for (int i = temporaryAppParticipateAry.count - insertRowCount; i < appParticipateAry.count; i++) {
                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i + insertRowCount inSection:section];
                                [paths addObject:indexPath];
                                [temporaryAppParticipateAry insertObject:[appParticipateAry objectAtIndex:i ] atIndex:temporaryAppParticipateAry.count];
                            }
                        }
                    }
                    
                    if(localPageNumber == 1){
                        if(temporaryAppFinishAry == nil){
                            temporaryAppFinishAry = [[NSMutableArray alloc] initWithArray:appFinishAry];
                        }else{
                            [temporaryAppFinishAry removeAllObjects];
                            [temporaryAppFinishAry insertObjects:appFinishAry atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, appFinishAry.count)]];
                        }
                    }else{
                        if(temporaryAppFinishAry.count != appFinishAry.count){
                            [sectionDic setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"ArrayTag5"]];
                            NSUInteger section = [self getCurrentSectionWithIndex:5];
                            int insertRowCount = 0;
                            if(oldIndexPath.section == section){
                                insertRowCount = insertRowsAry.count;
                            }
                            for (int i = temporaryAppFinishAry.count - insertRowCount; i < appFinishAry.count; i++) {
                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i + insertRowCount inSection:section];
                                [paths addObject:indexPath];
                                [temporaryAppFinishAry insertObject:[appFinishAry objectAtIndex:i ] atIndex:temporaryAppFinishAry.count];
                            }
                        }
                        
                    }
                    
                    if(temporaryLocalAppAry == nil){
                        temporaryLocalAppAry = [[NSMutableArray alloc] initWithArray:localAppAry];
                    }else{
                        [temporaryLocalAppAry removeAllObjects];
                        [temporaryLocalAppAry insertObjects:localAppAry atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, localAppAry.count)]];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(!isNeedShowGarnishedView && topView == nil){
                            UIImage *image = [UIImage imageNamed:@"pullDown"];
                            topView = [[UIImageView alloc] initWithFrame:CGRectMake(kmainScreenWidth/2 - image.size.width/2, -image.size.height, image.size.width, image.size.height)];
                            topView.image = image;
                            [_tableView addSubview:topView];
                        }else{
                            if(isNeedShowGarnishedView){
                                [topView removeFromSuperview];
                                topView = nil;
                            }
                        }
                        if(localPageNumber == 1){
                            [appIsOpenDic removeAllObjects];
                            [_tableView reloadData];
                        }else{
                            BOOL isSameSection = YES;
                            for(int i = 0 ; i < paths.count - 1 && paths.count > 1; i ++){
                                NSIndexPath *indexPath1 = [paths objectAtIndex:i];
                                NSIndexPath *indexPath2 = [paths objectAtIndex:i + 1];
                                if(indexPath1.section != indexPath2.section){
                                    isSameSection = NO;
                                    break;
                                }
                            }
                            if(!isSameSection){
                                [_tableView reloadData];
                            }else{
                                [_tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
                            }
                        }
                        localPageNumber ++;
                        temporaryLocalPageNumner = serviceCurrentPage;
                        _isRequesting = NO;
                        [[MyUserDefault standardUserDefaults] setDaTingRefreshTime:[NSNumber numberWithLongLong:[NSDate getNowTime]]];
                        [[LoadingView showLoadingView] actViewStopAnimation];
                        
                        if (serviceMaxNumber != 0) {        //分割线放到最后加
                            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, SeparateLineHeight)];
                            lineView.backgroundColor = kBlockBackground2_0;
                            [footerView addSubview:lineView];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"SuperLink" object:nil];
                    });
                    
                    
                });
                
                
                
            });
        });
    } fail:^(NSError *error) {
        NSLog(@"-----获取App【error】 = %@ -----",error);
        if(error.code == timeOutErrorCode){
            //连接超时
            if(timeOutCount < 2){
                timeOutCount ++;
                [self requestToApp];
            }else{
                timeOutCount = 0;
                _isRequesting = NO;
                [self showTimeoutAlertView:kTimeOutTag + 1];
                [[LoadingView showLoadingView] actViewStopAnimation];
            }
        }
    }];
}

/**
 *  请求发送签到状态
 *
 *  @param appId app的ID
 */
-(void)requestToSendSignType:(NSString *)appId{
    NSLog(@"appId = %@",appId);
    NSString *urlStr = [NSString stringWithFormat:kUrlPre,kOnlineWeb,@"GoldWashingUI",@"SetSign"];
    NSString *sid = [[MyUserDefault standardUserDefaults] getSid];
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString *dateStr = [formatter stringFromDate:date];
    NSString *md5 = [NSString stringWithFormat:@"%@%@%@",appId,dateStr,@"91signin"];
    NSLog(@"md5 = %@",md5);
    NSString *md5Code = [NSString md5Code:md5];
    NSLog(@"md5Code = %@",md5Code);
    NSDictionary *dic = @{@"AppId":appId, @"sid":sid, @"Sign":md5Code};
    NSLog(@"请求发送签到状态【urlStr】 = %@",urlStr);
    NSLog(@"请求发送签到状态【request】 = %@",dic);
    [AsynURLConnection requestWithURL:urlStr dataDic:dic timeOut:httpTimeout success:^(NSData *data) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"请求发送签到状态【response】 = %@",dataDic);
            int flag = [[dataDic objectForKey:@"flag"] intValue];
            if(flag == 1){
                NSLog(@"发送签到状态成功");
                //重新请求任务大厅
                [self requestToSpecialMisson];
            }
        });
    } fail:^(NSError *error) {
        
    }];
}

/**
 *  重新初始化app的对象信息
 *
 *  @param appsAry 服务器的app数据
 *
 */
-(NSMutableArray *)reinitAppAryObjects:(NSArray *)appsAry{
    NSMutableArray *groups = [[NSMutableArray alloc] init];
    for(NSDictionary *dic in appsAry){
        int index = [[dic objectForKey:@"MissionState"] integerValue];
        NSLog(@"MissionState = %d",index);
        GameGroup *group = [[GameGroup alloc] initGameAllInfor:dic andisOpen:NO index:index];
        NSArray *tasks = [dic objectForKey:@"Tasks"];
        for (int i = 0; i < tasks.count; i ++) {
            [group.subCells addObject:[tasks objectAtIndex:i]];
        }
        [groups addObject:group];
    }
    return groups;
}

/**
 *  网络异常对话框
 *
 *  @param tag 唯一标识
 */
-(void)showTimeoutAlertView:(int)tag{
    if(![UIAlertView isInit]){
        UIAlertView *netAlertView = [UIAlertView showNetAlert];
        netAlertView.delegate = self;
        netAlertView.tag = tag;
        [netAlertView show];
    }
}

-(void)statusBarAddBgView{
    if (IOS_Version >= 7.0) {
        UIView* view =[[UIView alloc]initWithFrame:CGRectMake(0, 0, kmainScreenWidth, 20)];
        view.backgroundColor =[UIColor blackColor];
        view.tag =37000;
        [[UIApplication sharedApplication].keyWindow addSubview:view];
    }
}
-(void)adjustStatusBar{
    if ([[UIApplication sharedApplication].keyWindow viewWithTag:37000]) {
        [[[UIApplication sharedApplication].keyWindow viewWithTag:37000] removeFromSuperview];
    }
}

// 米迪 代理
- (void)didShowWallView{
    //    [self statusBarAddBgView];
    
}
- (void)didDismissWallView{
    //    [self adjustStatusBar];
}
- (void)didReceiveOffers{
    NSLog(@"   力美success");
}
// 点入代理
-(void)didReceiveSpendScoreResult:(BOOL)isSuccess{
    
}
-(void)didReceiveGetScoreResult:(int)point{
    
}
//  以下2个点入代理必须有
-(NSString *)applicationKey{
    return kDianRuKey;
}
-(NSString *)dianruAdWallAppUserId{
    return userId;
}

//多盟代理
- (void)offerWallDidStartLoad{
    //    [self statusBarAddBgView];
}
- (void)offerWallDidFinishLoad{
    
}
- (void)offerWallDidClosed{
    //    [self adjustStatusBar];
}
- (void)offerWallDidFailLoadWithError:(NSError *)error{
    
}

// 力美
- (UIViewController *)immobViewController{
    return self;
}
//万普监听
-(void)onConnectSuccess:(NSNotification* )notic{
    //    [self statusBarAddBgView];
}
-(void)onOfferClosed:(NSNotification* )notic{
    //    [self adjustStatusBar];
}

// 艾德代理
- (void)offerWallDidFinishLoad:(MobiSageOfferWallViewController *)owInterstitial{
    //    [self statusBarAddBgView];
}
- (void)offerWallDidClosed:(MobiSageOfferWallViewController *)owInterstitial{
    //    [self adjustStatusBar];
}

/**
 *  显示有米的广告
 */
-(void)showYouMiAd{
    /*
     [YouMiConfig launchWithAppID:kYouMiId appSecret:kYouMiKey];
     [YouMiConfig setShouldGetLocation:NO];
     YouMiView *adView = [[YouMiView alloc]initWithContentSizeIdentifier:YouMiBannerContentSizeIdentifier320x50 delegate:self];
     [adView setIndicateTranslucency:YES];
     adView.frame =CGRectMake(0, kmainScreenHeigh-kfootViewHeigh-50, kmainScreenWidth, 50);
     adView.backgroundColor = [UIColor clearColor];
     [adView start];
     [self.view addSubview:adView];
     */
    adFailCount =0;
    dmAdView =[[DMAdView alloc] initWithPublisherId:kDuoMengPubID placementId:kDuoMengPlaceID autorefresh:YES];
    dmAdView.frame =CGRectMake(0, kmainScreenHeigh - kfootViewHeigh - 50 - (kBatterHeight), kmainScreenWidth, 50);
    dmAdView.delegate =self;
    dmAdView.rootViewController =self;
    [self.view addSubview:dmAdView];
    [dmAdView loadAd];
    if(_tableView.frame.size.height >= kmainScreenHeigh - _headToolBar.frame.origin.y - _headToolBar.frame.size.height - kfootViewHeigh - (kBatterHeight)){
        _tableView.frame = CGRectMake(_tableView.frame.origin.x, _tableView.frame.origin.y, _tableView.frame.size.width, _tableView.frame.size.height - dmAdView.frame.size.height);
    }
}

- (void)dmAdViewFailToLoadAd:(DMAdView *)adView withError:(NSError *)error{
    NSLog(@" _DMAD_%@",error.debugDescription);
    // 5次加载
    if (adFailCount <5) {
        [dmAdView loadAd];
        adFailCount ++;
    }
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end









