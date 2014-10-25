//
//  ShowPostsDetailViewController.m
//  91TaoJin
//
//  Created by keyrun on 14-6-3.
//  Copyright (c) 2014年 guomob. All rights reserved.
//

#import "ShowPostsDetailViewController.h"
#import "HeadToolBar.h"
#import "ShowPostsDetail.h"
#import "MyUserDefault.h"
#import "AsynURLConnection.h"
#import "LoadingView.h"
#import "ShowPostsDetailCommentCell.h"
#import "ShowPostsDetailCell.h"
#import "TaoJinLabel.h"
#import "TaoJinButton.h"
#import "UIImage+ColorChangeTo.h"
#import "NSString+IsEmply.h"
#import "StatusBar.h"
#import "TablePullToLoadingView.h"
#import "ViewTip.h"
#import "NSString+IsEmply.h"
#import "CommentTipCell.h"


#define SendViewHeight                                          47.0f                       //输入框的高度
#define SendButtonHeight                                        36.0f                       //发送按钮的高度
#define SendButtonWidth                                         60.0f                       //发送按钮的高度
#define TakePartCommentTip                                              @"这种只看贴不评论的行为\n你妈妈知道吗"
#define TakePartCommentTipHeight                                        200

@interface ShowPostsDetailViewController ()

@end

@implementation ShowPostsDetailViewController{
    UITableView *_tableView;
    UserShowPosts *_user;
    
    int pageNum;                                        //当前的请求页数
    int timeOutCount;                                   //连接超时次数
    int maxPage;                                        //服务器最大页数
    
    int localRow;                                       //加载到第几行
    
    ShowPostsDetail *detail;                            //晒单对象
    
    UIView *containView;                                //输入框所在的view
    HPGrowingTextView *textView;                        //输入框
    
    CGSize kbSize;                                      //键盘高度
    CGFloat normalKeyboardHeight;                       //
    
    TaoJinLabel *messageLab;                            //提示文案
    UIButton *sendBtn;                                  //发送按钮
    
    BOOL isFrist;
    
    ViewTip *tip;
    
    UIViewAnimationOptions animationOptions ;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithDetail:(UserShowPosts *)user{
    self = [super init];
    if(self){
        _user = user;
    }
    return self;
}

/**
 *  初始化变量
 */
- (void)initWithObjects{
    pageNum = 1;
    localRow = 1;
    isFrist = YES;
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

/**
 *  初始化输入框
 *
 *  @param frame 大小
 */
- (void)initWithTextViewFrame:(CGRect)frame{
    containView = [[UIView alloc] initWithFrame:frame];
    containView.backgroundColor = KLightGrayColor2_0;
    CALayer *layer = [CALayer layer];
    [layer setBackgroundColor:[kLineColor2_0 CGColor]];
    [layer setFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, LineWidth)];
    [containView.layer addSublayer:layer];
    textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 7, 240, 43)];
    textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
	textView.minNumberOfLines = 1;
	textView.maxNumberOfLines = 2;
    textView.backgroundColor = KLightGrayColor2_0;
    textView.internalTextView.backgroundColor = KLightGrayColor2_0;
	textView.returnKeyType = UIReturnKeyDefault;
	textView.font = [UIFont systemFontOfSize:15.0f];
	textView.delegate = self;
    textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textView.internalTextView.enablesReturnKeyAutomatically = YES;
    [textView setText:[[MyUserDefault standardUserDefaults] getShowPostsComment]];
    [containView addSubview:textView];
    containView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:containView];
    
    messageLab = [[TaoJinLabel alloc] initWithFrame:CGRectMake(15.0f, textView.frame.origin.y + 3.0f, 200.0, 30.0f) text:@"评论内容，不少于5个字哦" font:[UIFont systemFontOfSize:14] textColor:KGrayColor2_0 textAlignment:NSTextAlignmentLeft numberLines:1];
    [containView addSubview:messageLab];
    if(![NSString isEmply:[textView text]]){
        messageLab.hidden = YES;
    }else{
        messageLab.hidden = NO;
    }
    //发送按钮
    sendBtn = [[TaoJinButton alloc] initWithFrame:CGRectMake(kmainScreenWidth - 6.0f - SendButtonWidth, containView.frame.size.height/2 - SendButtonHeight/2, SendButtonWidth, SendButtonHeight) titleStr:@"发送" titleColor:KGreenColor2_0 font:[UIFont systemFontOfSize:14] logoImg:nil backgroundImg:[UIImage createImageWithColor:[UIColor whiteColor]]];
    [sendBtn setBackgroundImage:[UIImage createImageWithColor:kBlockBackground2_0] forState:UIControlStateHighlighted];
    [sendBtn.layer setBorderWidth:LineWidth];
    [sendBtn.layer setBorderColor:[kLineColor2_0 CGColor]];
    [sendBtn addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    [containView addSubview:sendBtn];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
    [self initWithObjects];
    
    HeadToolBar *headView = [[HeadToolBar alloc] initWithTitle:@"晒单详情" leftBtnTitle:@"返回" leftBtnImg:GetImage(@"back.png") leftBtnHighlightedImg:GetImage(@"back_sel.png") rightLabTitle:nil backgroundColor:KOrangeColor2_0];
    headView.leftBtn.tag = 1;
    [headView.leftBtn addTarget:self action:@selector(onClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:headView];
    
    if(_user.user_status == 3 || self.isPush==YES){
        [self initWithTableFrame:CGRectMake(0.0f, headView.frame.origin.y + headView.frame.size.height, kmainScreenWidth, kmainScreenHeigh - headView.frame.origin.y - headView.frame.size.height - SendViewHeight - (kBatterHeight))];
        [self.view addSubview:_tableView];
        [self initWithTextViewFrame:CGRectMake(0.0f, kmainScreenHeigh - SendViewHeight - (kBatterHeight), kmainScreenWidth, SendViewHeight )];
    }else{
        [self initWithTableFrame:CGRectMake(0.0f, headView.frame.origin.y + headView.frame.size.height, kmainScreenWidth, kmainScreenHeigh - headView.frame.origin.y - headView.frame.size.height - (kBatterHeight))];
        [self.view addSubview:_tableView];
    }

    _tableView.hidden = YES;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    UITapGestureRecognizer *doubletap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(touchToHidenKeyBoard:)];
    [doubletap setNumberOfTouchesRequired:1];
    [doubletap setNumberOfTapsRequired:1];
    [_tableView setUserInteractionEnabled:YES];
    [self.view setUserInteractionEnabled:YES];
    [_tableView addGestureRecognizer:doubletap];
    
    TablePullToLoadingView *loadingView = [[TablePullToLoadingView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, kTableLoadingViewHeight2_0)];
    _tableView.tableFooterView = loadingView;
    _tableView.tableFooterView.hidden = YES;
    
//    [[LoadingView showLoadingView] actViewStartAnimation];
    if (!self.isPush) {
        [self requestToGetShowPostsDetail:_user.user_showPostsId];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [[LoadingView showLoadingView] actViewStopAnimation];
}

/**
 *  发送按钮点击事件
 *
 */
-(void)sendAction:(id)sender{
    if (textView.text.length < 5) {
        [StatusBar showTipMessageWithStatus:@"评论内容不能少于5个字" andImage:GetImage(@"laba.png") andTipIsBottom:YES];
    }else{
        [self requestToSendComment:[textView text]];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(detail.detail_commentAry.count == 0 && detail.detail_status == 3)
        return 2;
    else if(detail.detail_commentAry.count == 0)
        return 1;
    return detail.detail_commentAry.count + 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row == 0){
        static NSString *ShowPostsDetailIdentifier = @"ShowPostsDetailIdentifier";
        ShowPostsDetailCell *cell = (ShowPostsDetailCell *)[tableView dequeueReusableCellWithIdentifier:ShowPostsDetailIdentifier];
        if(cell == nil){
            cell = [[ShowPostsDetailCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ShowPostsDetailIdentifier];
        }
        [cell showShowPostsDetail:detail];
        return cell;
    }else{
        if(detail.detail_commentAry.count > 0){
            static NSString *ShowPostsDetailCommentIdentifier = @"ShowPostsDetailCommentIdentifier";
            ShowPostsDetailCommentCell *cell = (ShowPostsDetailCommentCell *)[tableView dequeueReusableCellWithIdentifier:ShowPostsDetailCommentIdentifier];
            if(cell == nil){
                cell = [[ShowPostsDetailCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ShowPostsDetailCommentIdentifier];
            }
            [cell showComment:[detail.detail_commentAry objectAtIndex:indexPath.row - 1]];
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
        NSString *content = [NSString dealStringWithNewLine:detail.detail_content];
        CGSize size = [content sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(kmainScreenWidth - 2 * Spacing2_0, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
        float height = 0.0;
        for(NSDictionary *dic in detail.detail_pictureAry){
            float oldWidth1 = [[dic objectForKey:@"Width"] floatValue];
            float newWidth1 = oldWidth1 > (kmainScreenWidth - 2 * Spacing2_0) ? (kmainScreenWidth - 2 * Spacing2_0) : oldWidth1;
            float height1 = [[dic objectForKey:@"Height"] floatValue];
            height1 = height1 * newWidth1/oldWidth1;
            height += height1 + 9.0f;
        }
        return size.height + height + 46.0f + 9.0f + 9.0f;
    }else{
        if(detail.detail_commentAry.count > 0){
            Comment *comment = [detail.detail_commentAry objectAtIndex:indexPath.row - 1];
            NSString *content = [NSString dealStringWithNewLine:comment.comment_content];
            CGSize size = [content sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(kmainScreenWidth - 2 * Spacing2_0 - 8.0f - 37.0f, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
            return size.height + 46.0f + 9.0f + 9.0f;
        }else {
            return TakePartCommentTipHeight;
        }
    }
}

- (void)onClickBackBtn:(UIButton* )btn{
    switch (btn.tag) {
            //返回按钮
        case 1:
        {
            [[MyUserDefault standardUserDefaults] setShowPostsComment:[textView text]];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

/**
 *  请求获取晒单详情
 */
-(void)requestToGetShowPostsDetail:(int)showId{     //针对push消息 请求加入id参数
    if(isFrist){
        [[LoadingView showLoadingView] actViewStartAnimation];
        isFrist = NO;
    }
    self.showId =showId;
    NSString *urlStr = [NSString stringWithFormat:kUrlPre,kOnlineWeb,@"ActivityUI",@"GetShowOrderDetail"];
    NSString *sid = [[MyUserDefault standardUserDefaults] getSid];
    
    NSDictionary *dic = @{@"sid": sid, @"PageNum":[NSString stringWithFormat:@"%d",pageNum], @"Shid":[NSString stringWithFormat:@"%d",showId]};
    NSLog(@"获取晒单详情【urlStr】 = %@",urlStr);
    NSLog(@"获取晒单详情【request】 = %@",dic);
    [AsynURLConnection requestWithURL:urlStr dataDic:dic timeOut:httpTimeout success:^(NSData *data) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            timeOutCount = 0;
            NSLog(@"获取晒单详情【response】 = %@",dataDic);
            int flag = [[dataDic objectForKey:@"flag"] intValue];
            if(flag == 1){
                NSDictionary *body = [dataDic objectForKey:@"body"];
                maxPage = [[body objectForKey:@"MaxPage"] intValue];
                if(pageNum == 1){
                    //晒单详情对象
                    detail = [[ShowPostsDetail alloc] initWithShines:body];
                    
//                        tip = [[ViewTip alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kmainScreenWidth, kmainScreenHeigh)];
//                        [tip setViewTipByImage:[UIImage imageNamed:@"a3.png"]];
//                        [tip setViewTipByContent:ShowPostsCommentTip];
//                        [_tableView insertSubview:tip atIndex:1];
                    
                }else{
                    NSArray *comment = [body objectForKey:@"Comment"];
                    [detail insertCommentAry:comment];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                     _tableView.hidden = NO;
                     [[LoadingView showLoadingView] actViewStopAnimation];
                    if(pageNum == 1){
                        [_tableView reloadData];
                    }else{
                        //向下加载
                        NSMutableArray *paths = [[NSMutableArray alloc] init];
                        for (int i = localRow; i < detail.detail_commentAry.count; i++) {
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
                    localRow = detail.detail_commentAry.count;
                   
                    _tableView.tableFooterView.hidden = YES;
                });
            }else{
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [[LoadingView showLoadingView] actViewStopAnimation];
                 });
            }
        });
    } fail:^(NSError *error) {
        NSLog(@"获取活动列表【error】 = %@",error);
        if(error.code == timeOutErrorCode){
            //连接超时
            if(timeOutCount < 2){
                timeOutCount ++;
                [self requestToGetShowPostsDetail:showId];
            }else{
                timeOutCount = 0;
                [[LoadingView showLoadingView] actViewStopAnimation];
            }
        }
    }];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    float y_float = _tableView.contentOffset.y;
    if (y_float < 0)
        return;
    if(detail.detail_commentAry.count != 0 && pageNum <= maxPage && _tableView.tableFooterView.hidden == YES){
        CGPoint offset = scrollView.contentOffset;
        CGRect bounds = scrollView.bounds;
        CGSize size = scrollView.contentSize;
        UIEdgeInsets inset = scrollView.contentInset;
        float y = offset.y + bounds.size.height - inset.bottom;
        float h = size.height;
        if(y > h - 1) {
            _tableView.tableFooterView.hidden = NO;
            [self requestToGetShowPostsDetail:self.showId];
        }else{
            _tableView.tableFooterView.hidden = YES;
        }
    }
}

/**
 *  请求发送评论晒单内容
 */
-(void)requestToSendComment:(NSString *)commentStr{
    [[LoadingView showLoadingView] actViewStartAnimation];
    NSString *urlStr = [NSString stringWithFormat:kUrlPre,kOnlineWeb,@"ActivityUI",@"PostOrderReplay"];
    NSString *sid = [[MyUserDefault standardUserDefaults] getSid];
    int showpostId =_user.user_showPostsId;
    if (self.isPush) {
        showpostId =self.showId;
    }
//    commentStr = [self filterEmoji:commentStr];
    NSDictionary *dic = @{@"sid": sid, @"Content":commentStr, @"At":[NSString stringWithFormat:@"%d",showpostId]};
    NSLog(@"发送评论晒单内容【urlStr】 = %@",urlStr);
    NSLog(@"发送评论晒单内容【request】 = %@",dic);
    [AsynURLConnection requestWithURL:urlStr dataDic:dic timeOut:httpTimeout success:^(NSData *data) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            timeOutCount = 0;
            NSLog(@"发送评论晒单内容【response】 = %@",dataDic);
            int flag = [[dataDic objectForKey:@"flag"] intValue];
            NSString *messageOK = [dataDic objectForKey:@"message"];
            if(flag == 1 && [messageOK isEqualToString:@"ok"]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideKeyBoard];
                    NSDictionary *body = [dataDic objectForKey:@"body"];
                    NSDictionary *message = [body objectForKey:@"message"];
                    long long int time = [[body objectForKey:@"time"] longLongValue];
                    Comment *comment = [[Comment alloc] initWithCommentId:@"-1" content:commentStr pictureAry:nil userName:[[MyUserDefault standardUserDefaults] getUserNickname] userId:[[MyUserDefault standardUserDefaults] getUserId] userLogo:nil commentTime:[NSString stringWithFormat:@"%lld",time]];
                    [self resumnView:YES comment:comment];
                    [textView setText:@""];
                    if(message != nil){
                        NSNumber *goldNum = [message objectForKey:@"message"];
                        if(goldNum != nil){
                            int gold = [goldNum intValue];
                            if(gold > 0){
                                [StatusBar showTipMessageWithStatus:@"发送成功，" andImage:[UIImage imageNamed:@"icon_yes"] andCoin:[NSString stringWithFormat:@"+%d",gold] andSecImage:[UIImage imageNamed:@"tipBean"] andTipIsBottom:YES];
//                                [StatusBar showTipMessageWithStatus:[NSString stringWithFormat:@"发送成功，+%d金豆",gold] andImage:[UIImage imageNamed:@"laba.png"] andTipIsBottom:YES];
                            }else{
                                [StatusBar showTipMessageWithStatus:@"发送成功" andImage:[UIImage imageNamed:@"laba.png"] andTipIsBottom:YES];
                            }
                        }else{
                            [StatusBar showTipMessageWithStatus:@"发送成功" andImage:[UIImage imageNamed:@"laba.png"] andTipIsBottom:YES];
                        }
                    }else{
                        [StatusBar showTipMessageWithStatus:@"发送成功" andImage:[UIImage imageNamed:@"laba.png"] andTipIsBottom:YES];
                    }
                    [[LoadingView showLoadingView] actViewStopAnimation];
                    messageLab.hidden = NO;
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[LoadingView showLoadingView] actViewStopAnimation];
                });
            }
        });
    } fail:^(NSError *error) {
        NSLog(@"发送评论晒单内容【error】 = %@",error);
        if(error.code == timeOutErrorCode){
            //连接超时
            if(timeOutCount < 2){
                timeOutCount ++;
                [self requestToSendComment:commentStr];
            }else{
                timeOutCount = 0;
                [[LoadingView showLoadingView] actViewStopAnimation];
            }
        }
    }];
}



- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
	CGRect r = containView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	containView.frame = r;
    sendBtn.frame = CGRectMake(sendBtn.frame.origin.x, sendBtn.frame.origin.y - diff, sendBtn.frame.size.width, sendBtn.frame.size.height);
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if (range.location >= 200 || [NSString isContainsEmoji:text])
        return NO;
    else
        return YES;
}


- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView{
//    [messageLab setHidden:YES];
    /*
     if([growingTextView.text isEqualToString:NSLocalizedString(@"smsContent", nil)] && growingTextView.textColor == [UIColor grayColor])
     {
     growingTextView.text=@"";
     growingTextView.textColor=[UIColor blackColor];
     }
     */
}


  
- (void)growingTextViewDidEndEditing:(HPGrowingTextView *)growingTextView{
    NSString *text = [growingTextView text];
    if([NSString isEmply:text]){
        [messageLab setHidden:NO];
    }
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView{
    NSString *text = [growingTextView text];
    if([NSString isEmply:text]){
        [messageLab setHidden:NO];
    }else{
        [messageLab setHidden:YES];
    }

    if([NSString isEmply:text]){
        [sendBtn setEnabled:NO];
    }else {
        [sendBtn setEnabled:YES];
    }
}
/*
 *   即将显示键盘的处理
 */
-(void)keyBoardWillShow:(NSNotification*)notification{
    NSDictionary *info = [notification userInfo];
    //获取当前显示的键盘高度
    kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey ] CGRectValue].size;
    //获取当前键盘与上一次键盘的高度差
    CGFloat distanceToMove = kbSize.height - normalKeyboardHeight;
    
    UIViewAnimationCurve animationCurve ;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
     animationOptions =animationCurve << 16 ;
    
    [self keyboardToMoveView:distanceToMove isUp:YES isReloadTable:NO comment:nil animationOption:animationOptions];
    normalKeyboardHeight = kbSize.height;
    
    
}

/*
 *   键盘移动输入框跟随移动
 */
-(void)keyboardToMoveView:(int)height isUp:(BOOL)isUp isReloadTable:(BOOL)isReloadTable comment:(Comment *)comment animationOption:(UIViewAnimationOptions)options{
   
    [UIView animateWithDuration:0.25f delay:0.0f options:options  animations:^{
        CGRect smsBgcgreat = [containView frame];
        if(isUp){
            smsBgcgreat.origin.y -= height ;
        }else{
            smsBgcgreat.origin.y += height;
        }
        [containView setFrame:smsBgcgreat];
    } completion:^(BOOL finished) {
        if(finished && isReloadTable){
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
            [UIView animateWithDuration:0.5f animations:^{
                if(detail.detail_commentAry.count > 1){
                    [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                }
            }completion:^(BOOL finished) {
                if(finished){
                    [detail.detail_commentAry insertObject:comment atIndex:0];
                    if(detail.detail_commentAry.count > 1){
                        [_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }else{
                        [_tableView reloadData];
                    }
                    if(detail.detail_commentAry.count <= 1){
                        [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                    }
                }
            }];
        }
    }];

    
}

/*
 *   点击非输入框或键盘时隐藏键盘
 */
-(void)touchToHidenKeyBoard:(UITapGestureRecognizer*)recognizer
{
    [self hideKeyBoard];
    [self resumnView:NO comment:nil];
}

/*
 *   处理隐藏键盘
 */
-(void)hideKeyBoard
{
    [textView resignFirstResponder];
}

/*
 *   还原输入框的位置
 */
-(void)resumnView:(BOOL)isReloadTable comment:(Comment *)comment
{
    if(containView.frame.origin.y != kmainScreenHeigh - containView.frame.size.height){
        [self keyboardToMoveView:kbSize.height isUp:NO isReloadTable:isReloadTable comment:comment animationOption:animationOptions];
        normalKeyboardHeight = 0;
    }
}

/**
 *  滚动列表时收回键盘
 *
 */
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self hideKeyBoard];
    [self resumnView:NO comment:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end






