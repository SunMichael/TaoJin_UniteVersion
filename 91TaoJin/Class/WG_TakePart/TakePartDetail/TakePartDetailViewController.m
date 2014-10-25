//
//  TakePartDetailViewController.m
//  91TaoJin
//
//  Created by keyrun on 14-6-3.
//  Copyright (c) 2014年 guomob. All rights reserved.
//

#import "TakePartDetailViewController.h"
#import "HeadToolBar.h"
#import "MyUserDefault.h"
#import "AsynURLConnection.h"
#import "LoadingView.h"
#import "TakePartDetail.h"
#import "TakePartDetailCell.h"
#import "Comment.h"
#import "CommentCell2.h"
#import "TablePullToLoadingView.h"
#import "ViewTip.h"
#import "CommentTipCell.h"
#import "UIAlertView+NetPrompt.h"

#define TakePartCommentTip                                              @"这种只看贴不评论的行为\n你妈妈知道吗"
#define TakePartCommentTipHeight                                        200

@interface TakePartDetailViewController (){
    UITableView *_tableView;
    
    NSString *_takePartId;                              //活动ID
    NSMutableArray *_commentAry;                         //点评内容数组
    
    int pageNum;                                        //当前的请求页数
    int timeOutCount;                                   //连接超时次数
    int maxPage;                                        //服务器最大页数
    int localRow;                                       //加载到第几行
    
    TakePartDetail *takePartDetail;                     //活动详情对象
    TakePart *_partItem ;                                //活动对象
    
    UIWebView *_webView ;
    int webErrorCount ;
    NSString *webReqAdress ;
    HeadToolBar *headView ;
}

@end

@implementation TakePartDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithTakePartId:(NSString *)takePartId andTakePartItem:(TakePart *)takePartItem{
    self = [super init];
    if(self){
        _takePartId = takePartId;
        _partItem = takePartItem ;
    }
    return self;
}

/**
 *  初始化变量
 */
- (void)initWithObjects{
    pageNum = 1;
    localRow = 1;
    [[MyUserDefault standardUserDefaults] setPinLunLocationData:nil];  //清理评论本地数据
    _commentAry =[[NSMutableArray alloc] init];
}

/**
 *  初始化列表
 *
 *  @param frame 列表大小
 */
- (void)initWithTableFrame:(CGRect )frame{
    _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setSeparatorColor:[UIColor clearColor]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initWithObjects];
    
    headView = [[HeadToolBar alloc] initWithTitle:@"活动详情" leftBtnTitle:@"返回" leftBtnImg:GetImage(@"back.png") leftBtnHighlightedImg:GetImage(@"back_sel.png") rightLabTitle:nil backgroundColor:KOrangeColor2_0];
    headView.leftBtn.tag = 1;
    [headView.leftBtn addTarget:self action:@selector(onClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:headView];
	
    [self initWithTableFrame:CGRectMake(0.0f, headView.frame.origin.y + headView.frame.size.height, kmainScreenWidth, kmainScreenHeigh - headView.frame.origin.y - headView.frame.size.height - (kBatterHeight))];
    
    TablePullToLoadingView *loadingView = [[TablePullToLoadingView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, kTableLoadingViewHeight2_0)];
    _tableView.tableFooterView = loadingView;
    _tableView.tableFooterView.hidden = YES;
    
    if (!self.isPush) {
        if ( _partItem.takePart_type != 0 && _partItem.takePart_ispl == 0) {  //存在内嵌网页
            [self loadDetailsWebUrl];
        }else if(_partItem.takePart_ispl == 1 && _partItem.takePart_type == 0){
            [self requestToGetTakePartDetail:_takePartId];
        }else if (_partItem.takePart_type !=0 && _partItem.takePart_ispl == 1){
            
            [self performSelector:@selector(loadDetailsWebUrl) onThread:[NSThread currentThread] withObject:nil waitUntilDone:NO];
            [self requestToGetTakePartDetail:_takePartId];
            
        }else if (_partItem.takePart_ispl ==0 && _partItem.takePart_type ==0){   //不支持点评  不是网页数据
            [self requestToGetTakePartDetail:_takePartId];
        }
    }
    _tableView.hidden = YES;
    _tableView.backgroundColor =[UIColor clearColor];
    _tableView.delaysContentTouches =NO;
    [self.view addSubview:_tableView];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTabHeadCell) name:@"reloadTabHeadCell" object:nil];

}

-(void)reloadTabHeadCell{
    /*
     NSIndexPath *path =[NSIndexPath indexPathForRow:0 inSection:0];
     NSArray *array =[[NSArray alloc] initWithObjects:path, nil];
     [_tableView reloadRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationFade];
     */
    [_tableView reloadData];
}
-(void)loadDetailsWebUrl{
    
    if (![[LoadingView showLoadingView]actViewIsAnimation]) {
        [[LoadingView showLoadingView] actViewStartAnimation];
    }
    if (!_webView) {
        _webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, kmainScreenWidth , 1)];  //ios6下 如果webview frame 高度不设置会造成NAN错误
//        NSURL *url = [NSURL URLWithString:@"http://www.91taojin.com.cn/index.php?d=api2&c=OtherUI&m=SummerVacation&uid=7288480"];
        NSURL *url= [NSURL URLWithString:_partItem.takePart_url];
        NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:httpTimeout];
        [_webView loadRequest:request];
        
        webErrorCount =0;
        _webView.delegate = self;
        [(UIScrollView* )[[_webView subviews]objectAtIndex:0]setBounces:YES];
        _webView.scalesPageToFit =NO ;
        _webView.hidden =YES;
        _webView.scrollView.pagingEnabled =NO;
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
       
        if ( _partItem.takePart_type != 0 && _partItem.takePart_ispl == 0){
            _webView.userInteractionEnabled =YES;
            _webView.hidden = NO;
            _webView.frame =CGRectMake(0, headView.frame.origin.y +headView.frame.size.height, kmainScreenWidth, kmainScreenHeigh -headView.frame.origin.y -headView.frame.size.height);
        }
        _webView.backgroundColor =[UIColor clearColor];
        _webView.opaque = NO;
        [self.view addSubview:_webView];
    }
    
    webErrorCount =0 ;
    webReqAdress = _partItem.takePart_url ;
    
    
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    if (![[LoadingView showLoadingView] actViewIsAnimation]) {
        [[LoadingView showLoadingView] actViewStartAnimation];
    }
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:request.URL];  //活动网页上跳转链接时 ，webview不加载
        return NO;
    }else{
        return YES;
    }
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if (webErrorCount < 3) {
        NSURL *url = [NSURL URLWithString:webReqAdress];
        NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
        [_webView loadRequest:request];
        webErrorCount ++;
    }else{
        [[LoadingView showLoadingView] actViewStopAnimation];
        if(![UIAlertView isInit]){
            UIAlertView *alertView = [UIAlertView showNetAlert];
            alertView.tag = kTimeOutTag;
            alertView.delegate = self;
            [alertView show];
        }
        
    }
    
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    
    if (_partItem.takePart_type !=0 && _partItem.takePart_ispl == 1) {
        CGRect frame = webView.frame;
        frame.size.height = 1;
        webView.frame = frame;
        CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
        frame.size = fittingSize;
        webView.frame = frame;
        NSLog(@"web frame %f",frame.size.height);
    }
    
    if (webView.frame.size.height >1 ) {
        [[LoadingView showLoadingView] actViewStopAnimation];
        if (_partItem.takePart_ispl == 1) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTabHeadCell" object:nil];
        }else if(_partItem.takePart_ispl == 0 && _partItem.takePart_type !=0){     // 只有网页时
            [_webView removeFromSuperview];
            [self.view addSubview:_webView];
            
        }
    }
    
    
}

-(void)viewDidAppear:(BOOL)animated{
    
}

-(void)viewWillAppear:(BOOL)animated{
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [[LoadingView showLoadingView] actViewStopAnimation];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    //    if(_commentAry.count == 0)
    //        return 2;
    if (_partItem.takePart_type == 0 && _partItem.takePart_ispl ==1) {
        if (_commentAry.count == 0) {
            return 2 ;
        }else{
            return _commentAry.count +1 ;
        }
        
    }else if (_partItem.takePart_type == 0 && _partItem.takePart_ispl ==0){
        return 1;
    }
    else{
        if (_webView.frame.size.height > 1) {
            if (_commentAry.count == 0) {
                return 2 ;
            }else{
                return _commentAry.count + 1 ;
            }
        }else{
            return 0;
        }
    }
    return _commentAry.count + 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row == 0){
        static NSString *TaskPartIdentifier = @"TaskPartDetailCell";
        TakePartDetailCell *cell = (TakePartDetailCell *)[tableView dequeueReusableCellWithIdentifier:TaskPartIdentifier];
        if(cell == nil){
            cell = [[TakePartDetailCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TaskPartIdentifier];
        }
        /*
         [cell.takePartBtn addTarget:self action:@selector(onClickedJoinPL:) forControlEvents:UIControlEventTouchUpInside];
         [cell showTakePartDetail:takePartDetail];
         */
        if (_partItem.takePart_type == 0 && _partItem.takePart_ispl == 1) {
            [cell.takePartBtn addTarget:self action:@selector(onClickedJoinPL:) forControlEvents:UIControlEventTouchUpInside];
            [cell showTakePartDetail:takePartDetail];
        }else if (_partItem.takePart_type == 0 && _partItem.takePart_ispl == 0){
            cell.takePartBtn.hidden =YES;
            [cell hiddenTheLine];
            [cell showTakePartDetail:takePartDetail];
        }
        else{
            if (_partItem.takePart_ispl != 0 ) { // 支持评论 ,且是网页
                
                [cell.takePartBtn addTarget:self action:@selector(onClickedJoinPL:) forControlEvents:UIControlEventTouchUpInside];
                [_webView removeFromSuperview];
                _webView.hidden =NO;
                
                cell.takePartBtn.frame =CGRectMake(cell.takePartBtn.frame.origin.x, _webView.frame.size.height, cell.takePartBtn.frame.size.width, cell.takePartBtn.frame.size.height);
                if (_webView.frame.size.height > 1) {
                    cell.takePartBtn.hidden =NO;
                    
                }
                
                [cell resetCellLayerFrame];
                _webView.userInteractionEnabled =NO;
                [cell insertSubview:_webView belowSubview:cell.takePartBtn];

                /*
                for (UIView *currentView in cell.subviews)
                {
                    if([currentView isKindOfClass:[UIScrollView class]])
                    {
                        ((UIScrollView *)currentView).delaysContentTouches = NO;
                        break;
                    }
                }
                */
            }
            
        }
        
        return cell;
    }else{
        if(_commentAry.count > 0){
            static NSString *CommentIdentifier = @"CommentCell";
            CommentCell2 *cell = (CommentCell2 *)[tableView dequeueReusableCellWithIdentifier:CommentIdentifier];
            if(cell == nil){
                cell = [[CommentCell2 alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CommentIdentifier];
            }
            Comment *comment = [_commentAry objectAtIndex:indexPath.row - 1];
            [cell showComment:comment];
            return cell;
        }else{
            static NSString *CommentTipIdentifier = @"CommentTipCell";
            CommentTipCell *cell = (CommentTipCell *)[tableView dequeueReusableCellWithIdentifier:CommentTipIdentifier];
            if(cell == nil){
                cell = [[CommentTipCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CommentTipIdentifier rowHeight:TakePartCommentTipHeight content:TakePartCommentTip];
            }
            return cell;
        }
    }
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row == 0){
        if (_partItem.takePart_type == 0) {
            CGSize size = [takePartDetail.takePart_content sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(kmainScreenWidth - 2 * Spacing2_0, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
            float height = 0.0;
            for(NSDictionary *dic in takePartDetail.takePart_pictureAry){
                float oldWidth = [[dic objectForKey:@"Width"] floatValue];
                float newWidth = oldWidth > (kmainScreenWidth - 2 * Spacing2_0) ? (kmainScreenWidth - 2 * Spacing2_0) : oldWidth;
                float height2 = [[dic objectForKey:@"Height"] floatValue];
                height += height2 * newWidth/oldWidth + 9.0f;
            }
            if (_partItem.takePart_ispl == 0) {
                return size.height + height + 9.0f ;
            }
            return size.height + height + 41.0f + 9.0f + 9.0f + 9.0f;
        }else{
            if (_partItem.takePart_ispl ==1) {
                return _webView.frame.size.height + 41.0f + 9.0f + 10.0f ;
            }else{
                if (!_webView) {
                    return 0.0;
                }else{
                    
                    return _webView.frame.size.height ;
                }
            }
        }
        
    }else{
        /*
         Comment *comment = [_commentAry objectAtIndex:indexPath.row - 1];
         CGSize size = [comment.comment_content sizeWithFont:[UIFont systemFontOfSize:11] constrainedToSize:CGSizeMake(kmainScreenWidth - 2 * Spacing2_0, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
         float height = 0.0;
         for(id dic in comment.comment_pictureAry){
         if ([dic isKindOfClass:[NSData class]]) {
         UIImage *image =[UIImage imageWithData:dic];
         height +=image.size.height;
         }else{
         height += [[dic objectForKey:@"Height"] floatValue] + 9.0f;
         }
         }
         return size.height + height + 37.0f + 9.0f + 8.0f + 9.0f;
         */
        if(_commentAry.count > 0){
            CommentCell2 *cell = (CommentCell2 *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
            return [cell getCommentCellHeight];
        }else{
            return TakePartCommentTipHeight;
        }
    }
}


- (void)onClickBackBtn:(UIButton* )btn{
    switch (btn.tag) {
            //返回按钮
        case 1:
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

/**
 *  请求获取活动详情
 */
-(void)requestToGetTakePartDetail:(NSString *) tpID{
    if (![[LoadingView showLoadingView] actViewIsAnimation]) {
        if (pageNum ==1) {
            [[LoadingView showLoadingView] actViewStartAnimation];
        }
        
    }
    _takePartId =tpID;
    NSString *urlStr = [NSString stringWithFormat:kUrlPre,kOnlineWeb,@"ActivityUI",@"GetActDetail"];
    NSString *sid = [[MyUserDefault standardUserDefaults] getSid];
    NSDictionary *dic = @{@"sid": sid, @"PageNum":[NSString stringWithFormat:@"%d",pageNum], @"AtyId":tpID};
    NSLog(@"获取活动详情【urlStr】 = %@",urlStr);
    [AsynURLConnection requestWithURL:urlStr dataDic:dic timeOut:httpTimeout success:^(NSData *data) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            timeOutCount = 0;
            NSLog(@"获取活动详情【response】 = %@",dataDic);
            int flag = [[dataDic objectForKey:@"flag"] intValue];
            if(flag == 1){
                NSDictionary *body = [dataDic objectForKey:@"body"];
                maxPage = [[body objectForKey:@"MaxPage"] intValue];
                NSDictionary *aty = [body objectForKey:@"Aty"];
                //活动详情对象
                NSArray *comment = [body objectForKey:@"Comment"];
                if(pageNum == 1){
                    takePartDetail = [[TakePartDetail alloc] initWithTakePartId:[aty objectForKey:@"Aid"] content:[aty objectForKey:@"Content"] pictureAry:[aty objectForKey:@"Pic"]];
                    _commentAry = [self reinitCommentAryObjects:comment];
                }else{
                    [_commentAry insertObjects:[self reinitCommentAryObjects:comment] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_commentAry.count, comment.count)]];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _tableView.hidden = NO;
                    if(pageNum == 1){
                        [_tableView reloadData];
                    }else{
                        //向下加载
                        NSMutableArray *paths = [[NSMutableArray alloc] init];
                        for (int i = localRow; i < _commentAry.count; i++) {
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i+1 inSection:0];
                            [paths addObject:indexPath];
                        }
                        [_tableView insertRowsAtIndexPaths:[NSArray arrayWithArray:paths] withRowAnimation:UITableViewRowAnimationFade];
                        NSIndexPath *localIndexPath = [NSIndexPath indexPathForRow:localRow inSection:0];
                        [UIView animateWithDuration:0.5f animations:^{
                            //                                [self scrollToRowAtIndexPath:localIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
                        }];
                    }
                    pageNum ++;
                    localRow = _commentAry.count;
                    if (_partItem.takePart_type == 0) {
                        [[LoadingView showLoadingView] actViewStopAnimation];
                    }
                    if ([[LoadingView showLoadingView] actViewIsAnimation]) {
                        [[LoadingView showLoadingView] actViewStopAnimation];
                    }
                    _tableView.tableFooterView.hidden = YES;
                });
            }
        });
    } fail:^(NSError *error) {
        NSLog(@"获取活动列表【error】 = %@",error);
        if(error.code == timeOutErrorCode){
            //连接超时
            if(timeOutCount < 2){
                timeOutCount ++;
                [self requestToGetTakePartDetail:tpID];
            }else{
                timeOutCount = 0;
                [[LoadingView showLoadingView] actViewStopAnimation];
            }
        }
    }];
}

/**
 *  转换服务器数据为点评对象
 *
 *  @param commentAry 服务器的数据
 *
 */
-(NSMutableArray *)reinitCommentAryObjects:(NSArray *)commentAry{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:commentAry.count];
    for(NSDictionary *dic in commentAry){
        Comment *comment = [[Comment alloc] initWithCommentId:[dic objectForKey:@"Id"] content:[dic objectForKey:@"Content"] pictureAry:[dic objectForKey:@"Pic"] userName:[dic objectForKey:@"UserNickName"] userId:[dic objectForKey:@"UserId"] userLogo:[dic objectForKey:@"UserPic"] commentTime:[dic objectForKey:@"Time"]];
        [array addObject:comment];
    }
    return array;
}

-(void)onClickedJoinPL:(TaoJinButton *)button{
    CommentViewController *commentVC =[[CommentViewController alloc] initWithNibName:nil bundle:nil];
    commentVC.delegate = self;
    commentVC.topicId =_takePartId;
    commentVC.commentType =CommentTypePinLun;
    [self.navigationController presentViewController:commentVC animated:YES completion:^{
        
    }];
}

-(void)reloadView:(id)object{
    NSDictionary *dic = (NSDictionary *)object;
    
    NSIndexPath *indexPath =[NSIndexPath indexPathForRow:1 inSection:0];
    [UIView animateWithDuration:0.5f animations:^{
        if(_commentAry.count > 1){
            [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
    }completion:^(BOOL finished) {
        //        if(finished){
        Comment *comment = [[Comment alloc] initCommentWithDic:dic];
        [_commentAry insertObject:comment atIndex:0];
        if(_commentAry.count == 1){
            NSIndexPath *deletePath = [NSIndexPath indexPathForRow:1 inSection:0];
            [_tableView reloadRowsAtIndexPaths:@[deletePath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }else{
            [_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        }
        if(_commentAry.count <= 1){
            [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
        //        }
    }];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    float y_float = _tableView.contentOffset.y;
    if (y_float < 0)
        return;
    if(_commentAry.count != 0 && pageNum <= maxPage && _tableView.tableFooterView.hidden == YES){
        CGPoint offset = scrollView.contentOffset;
        CGRect bounds = scrollView.bounds;
        CGSize size = scrollView.contentSize;
        UIEdgeInsets inset = scrollView.contentInset;
        float y = offset.y + bounds.size.height - inset.bottom;
        float h = size.height;
        if(y > h - 1) {
            _tableView.tableFooterView.hidden = NO;
            if (_partItem.takePart_ispl == 1) {
                [self requestToGetTakePartDetail:_takePartId];
            }else{
                _tableView.tableFooterView.hidden = YES;
            }
            
        }else{
            _tableView.tableFooterView.hidden = YES;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end





