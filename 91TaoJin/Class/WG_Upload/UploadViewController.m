//
//  UploadViewController.m
//  91TaoJin
//
//  Created by keyrun on 14-6-11.
//  Copyright (c) 2014年 guomob. All rights reserved.
//

#import "UploadViewController.h"
#import "HeadToolBar.h"
#import "TaoJinLabel.h"
#import "TaoJinButton.h"
#import "UIImage+ColorChangeTo.h"
#import "UniversalTip.h"
#import "TJViewController.h"
#import "CompressImage.h"
#import "StatusBar.h"
#import "LoadingView.h"
#import "MyUserDefault.h"
#import "JSONKit.h"
#import "AsynURLConnection.h"
#import "MScrollVIew.h"
#import "ShowImgView.h"
#import "CompressImage.h"

#define kDefShowImgW 149.0
#define kDefShowImgH 224.0
#define kBtnSizeH    40.0
#define kIpadScale2 0.75      //高宽比

@interface UploadViewController ()
{
    HeadToolBar *headBar;
    
    BOOL firstImage;
    BOOL secImage;
    NSMutableArray *btnArray;
    int phoneIndex;
    NSMutableArray *getImages;      //收集上传的图片
    NSMutableArray *dataArray;      // 图片数据数组
    BOOL isSuitable ;              // 选取的图片 符合要求
    MScrollVIew *ms;
    
}
@end

@implementation UploadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        firstImage =NO;
        secImage =NO;
    }
    return self;
}
-(void)onClickedGoBackBtn{
    if (firstImage ==YES || secImage ==YES) {
        UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"放弃本次编辑？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"放弃", nil];
        [alertView show];
    }else{
//        [self.navigationController popViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex ==1) {
//        [self.navigationController popViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    headBar =[[HeadToolBar alloc] initWithTitle:@"上传截图" leftBtnTitle:@"返回" leftBtnImg:GetImage(@"back.png") leftBtnHighlightedImg:GetImage(@"back_sel.png") rightBtnTitle:nil rightBtnImg:nil rightBtnHighlightedImg:nil backgroundColor:KOrangeColor2_0];
    [headBar.leftBtn addTarget:self action:@selector(onClickedGoBackBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:headBar];
    
    
    ms = [[MScrollVIew alloc] initWithFrame:CGRectMake(0, headBar.frame.origin.y + headBar.frame.size.height, kmainScreenWidth, kmainScreenHeigh - headBar.frame.origin.y - headBar.frame.size.height) andWithPageCount:1 backgroundImg:nil];
    ms.bounces =YES;
    ms.backgroundColor= [UIColor whiteColor];
    [ms setContentSize:CGSizeMake(kmainScreenWidth, ms.frame.size.height+1)];
    if (kmainScreenHeigh < 568.0f) {
        [ms setContentSize:CGSizeMake(kmainScreenWidth, ms.frame.size.height+45)];
    }
    [self.view addSubview:ms];
    
    NSLog(@" tip %@",self.taskPhoto.taskPhoto_tipString);
    phoneIndex =0;
    btnArray =[[NSMutableArray alloc] init];
    getImages =[[NSMutableArray alloc] initWithObjects:[[NSNull alloc]init],[[NSNull alloc]init], nil];
    dataArray =[[NSMutableArray alloc] initWithArray:@[[[NSNull alloc] init],[[NSNull alloc] init]]];
    [self loadContentView];
}

-(TaoJinButton *)loadShowImgBtnWithFrame:(CGRect) frame andTitle:(NSString *)title andLogoImg:(UIImage *)img andTag:(int)tag{
    TaoJinButton *btn =[[TaoJinButton alloc] initWithFrame:frame titleStr:title titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:14.0f] logoImg:img backgroundImg:[UIImage createImageWithColor:KOrangeColor2_0]];
    btn.adjustsImageWhenHighlighted =NO;
    btn.tag =tag;
    btn.imageEdgeInsets =UIEdgeInsetsMake(7.0f, 30.0f, 7.0f, 90.0f);
    [btn addTarget:self action:@selector(onClickedShowImg:) forControlEvents:UIControlEventTouchUpInside];
    [btn setBackgroundImage:[UIImage createImageWithColor:KLightOrangeColor2_0] forState:UIControlStateHighlighted];
    return btn;
}
-(void)loadContentView{
    TaoJinLabel *contentLab =[[TaoJinLabel alloc] initWithFrame:CGRectMake(kOffX_float, 10, kmainScreenWidth - 2 *kOffX_float, 0) text:self.taskPhoto.taskPhoto_missionDes font:[UIFont systemFontOfSize:14.0] textColor:KBlockColor2_0 textAlignment:NSTextAlignmentLeft numberLines:0];
    [contentLab sizeToFit];
    contentLab.frame =CGRectMake(kOffX_float, 10, kmainScreenWidth -2 *kOffX_float, contentLab.frame.size.height);
    [ms addSubview:contentLab];
    /*
     TaoJinButton *showImgBtn =[[TaoJinButton alloc] initWithFrame:CGRectMake((kmainScreenWidth -151.0)/2, contentLab.frame.origin.y +contentLab.frame.size.height , 151, 0)];
     if (self.taskPhoto.taskPhoto_imageAry.count >0) {
     
     showImgBtn =[[TaoJinButton alloc]initWithFrame:CGRectMake((kmainScreenWidth -151.0)/2, contentLab.frame.origin.y +contentLab.frame.size.height +10, 151, 40) titleStr:@"示例图" titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:14.0f] logoImg:GetImage(@"icon_appStore") backgroundImg:[UIImage createImageWithColor:KOrangeColor2_0]];
     showImgBtn.tag =1;
     showImgBtn.adjustsImageWhenHighlighted =NO;
     showImgBtn.imageEdgeInsets =UIEdgeInsetsMake(7.0f, 30.0f, 7.0f, 90.0f);
     [showImgBtn addTarget:self action:@selector(onClickedShowImg:) forControlEvents:UIControlEventTouchUpInside];
     [showImgBtn setBackgroundImage:[UIImage createImageWithColor:KLightOrangeColor2_0] forState:UIControlStateHighlighted];
     [ms addSubview:showImgBtn];
     }
     
     if (self.taskPhoto.taskPhoto_isPl ==1) {
     showImgBtn.frame =CGRectMake(kOffX_float, showImgBtn.frame.origin.y, 151.0, 40.0);
     TaoJinButton *plBtn =[[TaoJinButton alloc] initWithFrame:CGRectMake(showImgBtn.frame.origin.x +showImgBtn.frame.size.width +2, showImgBtn.frame.origin.y, 151.0, 40.0) titleStr:@"去评论" titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:14.0f] logoImg:GetImage(@"icon_showImg") backgroundImg:[UIImage createImageWithColor:KOrangeColor2_0]];
     plBtn.tag =2;
     plBtn.adjustsImageWhenHighlighted= NO;
     plBtn.imageEdgeInsets =UIEdgeInsetsMake(7.0f, 30.0f, 7.0f, 90.0f);
     [plBtn setBackgroundImage:[UIImage createImageWithColor:KLightOrangeColor2_0] forState:UIControlStateHighlighted];
     [plBtn addTarget:self action:@selector(onClickedShowImg:) forControlEvents:UIControlEventTouchUpInside];
     [ms addSubview:plBtn];
     }  */
    TaoJinButton *showImgBtn ;
    TaoJinButton *plBtn;
    if (self.taskPhoto.taskPhoto_imageAry.count >0 ) {
        showImgBtn =[self loadShowImgBtnWithFrame:CGRectMake((kmainScreenWidth -151.0)/2, contentLab.frame.origin.y +contentLab.frame.size.height +10, 151, kBtnSizeH) andTitle:@"示例图" andLogoImg:GetImage(@"icon_appStore") andTag:1];
        [ms addSubview:showImgBtn];
        if (self.taskPhoto.taskPhoto_isPl ==1) {
            showImgBtn.frame =CGRectMake(kOffX_float, showImgBtn.frame.origin.y, 151.0, kBtnSizeH);
            plBtn = [self loadShowImgBtnWithFrame:CGRectMake(showImgBtn.frame.origin.x +showImgBtn.frame.size.width +2, showImgBtn.frame.origin.y, 151.0, kBtnSizeH) andTitle:@"去评论" andLogoImg:GetImage(@"icon_showImg") andTag:2];
            [ms addSubview:plBtn];
        }
    }else{
        if (self.taskPhoto.taskPhoto_isPl ==1) {
            plBtn = [self loadShowImgBtnWithFrame:CGRectMake((kmainScreenWidth -151.0)/2, contentLab.frame.origin.y +contentLab.frame.size.height +10, 151, kBtnSizeH) andTitle:@"去评论" andLogoImg:GetImage(@"icon_showImg") andTag:2];
            [ms addSubview:plBtn];
        }
    }
    
    
    NSArray *tips ;
    if (self.taskPhoto.taskPhoto_tipString) {
        tips =[NSArray arrayWithObjects:self.taskPhoto.taskPhoto_tipString, nil];
    }
    UniversalTip *tip =[[UniversalTip alloc] initWithFrame:CGRectMake(kOffX_float, contentLab.frame.origin.y +contentLab.frame.size.height +10, kmainScreenWidth -2 *kOffX_float, 0) andTips:tips andTipBackgrundColor:KTipBackground2_0 withTipFont:[UIFont systemFontOfSize:11.0] andTipImage:GetImage(@"tips_3.png") andTipTitle:@"截图提示：" andTextColor:KOrangeColor2_0];
    if (showImgBtn.frame.size.height >0 || plBtn.frame.size.height >0) {
        tip.frame =CGRectMake(kOffX_float, contentLab.frame.origin.y +contentLab.frame.size.height +10 +kBtnSizeH +10, kmainScreenWidth -2 *kOffX_float, tip.frame.size.height);
    }
    [ms addSubview:tip];
    
    TaoJinButton *imgOne =[[TaoJinButton alloc]initWithFrame:CGRectMake((kmainScreenWidth -kDefShowImgW)/2, tip.frame.origin.y +tip.frame.size.height +10, kDefShowImgW , kDefShowImgH) titleStr:nil titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:14.0f] logoImg:nil backgroundImg:GetImage(@"showImgDef")];
    imgOne.adjustsImageWhenHighlighted =NO;
    imgOne.tag =0;
    [imgOne addTarget:self action:@selector(getImgFromLocation:) forControlEvents:UIControlEventTouchUpInside];
    [ms addSubview:imgOne];
    [btnArray addObject:imgOne];
    
    if (self.taskPhoto.taskPhoto_imgCount >1) {
        imgOne.frame =CGRectMake(kOffX_float, tip.frame.origin.y +tip.frame.size.height +10, kDefShowImgW, kDefShowImgH);
        TaoJinButton *imgTwo  =[[TaoJinButton alloc]initWithFrame:CGRectMake(kOffX_float +imgOne.frame.size.width + 6.0f, imgOne.frame.origin.y, kDefShowImgW , kDefShowImgH) titleStr:nil titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:14.0f] logoImg:nil backgroundImg:GetImage(@"showImgDef")];
        imgTwo.tag =1;
        [imgTwo addTarget:self action:@selector(getImgFromLocation:) forControlEvents:UIControlEventTouchUpInside];
        imgTwo.adjustsImageWhenHighlighted =NO;
        [ms addSubview:imgTwo];
        [btnArray addObject:imgTwo];
        
    }
    
    TaoJinButton *uploadBtn =[[TaoJinButton alloc]initWithFrame:CGRectMake(kOffX_float, imgOne.frame.origin.y +imgOne.frame.size.height +10, kmainScreenWidth -2* kOffX_float , 40) titleStr:[NSString stringWithFormat:@"上传截图"] titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:16.0f] logoImg:nil backgroundImg:[UIImage createImageWithColor:KGreenColor2_0]];
    [uploadBtn addTarget:self action:@selector(upLoadImgBtn) forControlEvents:UIControlEventTouchUpInside];
    [ms addSubview:uploadBtn];
    
    [ms setContentSize:CGSizeMake(kmainScreenWidth, uploadBtn.frame.origin.y +uploadBtn.frame.size.height +40)];
}
-(void)upLoadImgBtn{       //点击上传
    
    CGSize screenSize =[UIScreen mainScreen].bounds.size;
    float scale =[UIScreen mainScreen].scale;
    if (firstImage ==YES && secImage ==YES && btnArray.count == 2) {
        UIImage *image =[getImages objectAtIndex:0];
        
        UIImage *image2 =[getImages objectAtIndex:1];
        
        CGSize size1 =image.size;
        CGSize size2 =image2.size;
        if ([[UIDevice currentDevice].model isEqualToString:@"iPad"]) {
            [self creatUploadImgRequest];
            /*
            float scale1 =  (size1.height )/size1.width;
            float scale2 = (size2.height )/size2.width;
            float scaleWH1 =size1.width /size1.height;
            float scaleWH2 =size2.width /size2.height;
            if (scale1 ==scale2 && scale1 ==kIpadScale2) {
                [self creatUploadImgRequest];
            }else if (scaleWH1 ==scaleWH2 && scaleWH1 ==kIpadScale2){
                [self creatUploadImgRequest];
            }
            else{
                [StatusBar showTipMessageWithStatus:@"上传的图片尺寸不符合要求" andImage:GetImage(@"laba.png") andTipIsBottom:YES];
            }
     */
        }else{
            screenSize =CGSizeMake(screenSize.width *scale, screenSize.height *scale);
            if (CGSizeEqualToSize(size1, size2) ==YES && CGSizeEqualToSize(size2, screenSize) ==YES) {
                [self creatUploadImgRequest];
            }else{
                [StatusBar showTipMessageWithStatus:@"上传的图片尺寸不符合要求" andImage:GetImage(@"laba.png") andTipIsBottom:YES];
            }
        }
    }else if (btnArray.count ==1 && firstImage ==YES){
        
        UIImage *image =[getImages objectAtIndex:0];
        if ([[UIDevice currentDevice].model isEqualToString:@"iPad"]) {
            float scale1 = (image.size.height *1.0)/(image.size.width *1.0) ;
            float scale2 = image.size.width /image.size.height;
            if ( scale1 == kIpadScale2 || scale2 ==kIpadScale2) {
                [self creatUploadImgRequest];
            }else{
                [StatusBar showTipMessageWithStatus:@"上传的图片尺寸不符合要求" andImage:GetImage(@"laba.png") andTipIsBottom:YES];
            }
        }else{
            
            if (CGSizeEqualToSize(image.size, CGSizeMake(screenSize.width *scale, screenSize.height *scale))) {
                [self creatUploadImgRequest];
            }else{
                [StatusBar showTipMessageWithStatus:@"上传的图片尺寸不符合要求" andImage:GetImage(@"laba.png") andTipIsBottom:YES];
            }
        }
    }else if ( btnArray.count ==2  && firstImage ==YES){
        [StatusBar showTipMessageWithStatus:@"请插入第二张截图后上传" andImage:GetImage(@"laba.png") andTipIsBottom:YES];
    }else if (btnArray.count ==2 && secImage ==YES){
        [StatusBar showTipMessageWithStatus:@"请插入第二张截图后上传" andImage:GetImage(@"laba.png") andTipIsBottom:YES];
    }
    else{
        [StatusBar showTipMessageWithStatus:@"请插入截图后上传" andImage:GetImage(@"laba.png") andTipIsBottom:YES];
    }
}
-(void)getImgFromLocation:(TaoJinButton *)btn{       //取本地图片
    phoneIndex =btn.tag;
    UICollectionViewFlowLayout *layout =[[UICollectionViewFlowLayout alloc] init];
    PhotoViewController *photoVC =[[PhotoViewController alloc] initWithCollectionViewLayout:layout];
    photoVC.pvDelegate =self;
    [self presentViewController:photoVC animated:YES completion:^{
    
    }];

}
-(void)getImageFromLocation:(UIImage *)image{
    //    UIButton *phoneBtn2 = [realBtns objectAtIndex:phoneIndex];
    //    [phoneBtn2 setBackgroundImage:image forState:UIControlStateNormal];
    [getImages replaceObjectAtIndex:phoneIndex withObject:image];
    
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [dataArray replaceObjectAtIndex:phoneIndex withObject:[self getImageData:image]];
    //    });
    
    if (image.size.height > 960.0f) {
        float scale =kDefShowImgW*1.0 /(kmainScreenWidth*1.0);
        CGSize newSize =CGSizeMake(kDefShowImgW, image.size.height *scale*0.5);
        //        image =[CompressImage imageWithOldImage:image scaledToSize:newSize];
        //        image =[self getResultImageFrom:image inRect:CGRectMake(0, newSize.height/2 -kDefShowImgH/2, kDefShowImgW, kDefShowImgH)];
        image = [CompressImage imageWithCutImage:image moduleSize:newSize];
    }else{
        image = [CompressImage imageWithOldImage:image scaledToSize:CGSizeMake(kDefShowImgW, kDefShowImgH)];
    }
    UIButton *phoneBtn = [btnArray objectAtIndex:phoneIndex];
    [phoneBtn setBackgroundImage:image forState:UIControlStateNormal];
    switch (phoneIndex) {
        case 0:
            firstImage =YES;
            break;
        case 1:
            secImage =YES;
            break;
        default:
            break;
    }
    
}
-(NSData *)getImageData:(UIImage *)image{
    NSData* dataImg = UIImagePNGRepresentation(image);
    NSLog(@"  imagesize %@ %d ",NSStringFromCGSize(image.size),dataImg.length);
    if (dataImg.length > 100*1024) {
        dataImg = UIImageJPEGRepresentation(image, 0.1);
        NSLog(@" big %d",dataImg.length);
    }else if(dataImg.length > 50*1024 && dataImg.length < 100 *1024){
        dataImg = UIImageJPEGRepresentation(image,0.6);
        NSLog(@" small %d",dataImg.length);
    }
    return dataImg;
}
-(UIImage *)getResultImageFrom:(UIImage *)image inRect:(CGRect) rect{
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}
-(void)onClickedShowImg:(TaoJinButton *)btn{
    switch (btn.tag) {
        case 1:        // 展示示例图
        {
            
            ShowImgView *view =[[ShowImgView alloc] initWithImgListArr:self.taskPhoto.taskPhoto_imageAry];
            [view showImages];
            
        }
            break;
        case 2:         // 评论
        {
            NSURL *url =[NSURL URLWithString:self.taskPhoto.taskPhoto_commentUrl];
            [[UIApplication sharedApplication] openURL:url];
        }
            break;
        default:
            break;
    }
}
-(void)creatUploadImgRequest{
    
    [[LoadingView showLoadingView] actViewStartAnimation];
    for (TaoJinButton *btn in btnArray) {
        btn.userInteractionEnabled =NO;
    }
    NSString *sid = [[MyUserDefault standardUserDefaults] getSid];
    NSString *boundary;
    NSMutableDictionary *dic;
    NSString* urlStr;
    NSNumber *num;
    int rand =arc4random()/100000;
    num =[NSNumber numberWithInt:rand];
    
    NSString *tid =[NSString stringWithFormat:@"%d",self.taskPhoto.taskPhoto_appId];
    NSString *listorder =[NSString stringWithFormat:@"%d",self.taskPhoto.taskPhoto_step];
    
    dic =[[NSMutableDictionary alloc] initWithDictionary:@{@"sid": sid,@"Tid":tid ,@"Listorder":listorder}];     //需要活动id 和任务序列id
    urlStr =[NSString stringWithFormat:kUrlPre,kOnlineWeb,@"GoldWashingUI",@"JoinScreenShotMission"];
    NSLog(@"请求上传截图【urlStr】= %@   %@",urlStr,dic);
    
    NSString *paramStr = [dic JSONString];
    /*
     if(firstImage){
     
     NSObject *obj =[getImages objectAtIndex:0];
     [dic setObject:(UIImage *)obj forKey:[NSString stringWithFormat:@"userPic0"]];
     
     }
     if(secImage){
     
     NSObject *obj2 =[getImages objectAtIndex:1];
     [dic setObject:(UIImage *)obj2 forKey:[NSString stringWithFormat:@"userPic1"]];
     }
     */
    NSMutableData* body = [NSMutableData data];
    boundary = @"0xKhTmLbOuNdArY";
    [body appendData:[[NSString stringWithFormat:@"\n--%@\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition:form-data;name='PARAM';value='%@'\n\n",paramStr] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"{\"sid\":\"%@\",\"Tid\":\"%@\",\"Listorder\":\"%@\"}",sid ,tid,listorder] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\n--%@\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //第二段
    int imageTag=0;
    
    //将字典排序 不然图片顺序会乱
    NSArray* array = dic.allKeys;
    array = [array sortedArrayUsingComparator:^(id obj1 ,id obj2){
        NSComparisonResult result = [obj1 compare:obj2];
        return result == NSOrderedDescending;
    }];
    
    for (int i = 0; i < dataArray.count; i++) {
        id value =[dataArray objectAtIndex:i];
        if (![value isKindOfClass:[NSNull class]]) {
            NSData *dataImg =[dataArray objectAtIndex:i];
            
            /*
             NSString *key = [array objectAtIndex:i];
             id value = [dic objectForKey:key];
             if ([value isKindOfClass:[UIImage class]]) {
             UIImage* im = [dic objectForKey:key];
             
             NSData* dataImg =[NSData dataWithData: UIImageJPEGRepresentation(im, 1.0)];
             if (dataImg.length > 100*1024) {
             dataImg = UIImageJPEGRepresentation(im, .08);
             }else if(dataImg.length > 50*1024 && dataImg.length < 100 *1024){
             dataImg = UIImageJPEGRepresentation(im, 0.3);
             }
             */
            [body appendData:[[NSString stringWithFormat:@"\n--%@\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition:form-data;name='userfile_%d';filename='userfile.jpg'\n",i] dataUsingEncoding:NSUTF8StringEncoding]];
            imageTag++;
            [body appendData:[[NSString stringWithFormat:@"Content-Type:image/jpg\n\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:dataImg];
            [body appendData:[[NSString stringWithFormat:@"\n--%@--\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    NSLog(@" img body %d",body.length);
    [AsynURLConnection requestWithURLToSendJSONL:urlStr boundary:boundary paramStr:paramStr body:body timeOut:httpTimeout+30 success:^(NSData *data) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error;
            NSDictionary *dataDic =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            NSLog(@"error【reaponse】 = %@",error);
            NSLog(@"上传截图【reaponse】 = %@",dataDic);
            if ([[dataDic objectForKey:@"flag"]intValue]==1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [StatusBar showTipMessageWithStatus:@"截图上传成功，请等待审核" andImage:GetImage(@"icon_yes.png") andTipIsBottom:YES];
                    
                    [self dismissViewControllerAnimated:YES completion:^{
                        
                    }];
                    [self.delegate uploadImageSuccess];
                    [[LoadingView showLoadingView] actViewStopAnimation];
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [StatusBar showTipMessageWithStatus:@"上传截图失败，请重新上传" andImage:[UIImage imageNamed:@"icon_no.png"] andTipIsBottom:YES];
                    [[LoadingView showLoadingView] actViewStopAnimation];
                });
            }
            for (TaoJinButton *btn in btnArray) {
                btn.userInteractionEnabled =YES;
            }
        });
    } fail:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[LoadingView showLoadingView] actViewStopAnimation];
            [StatusBar showTipMessageWithStatus:@"上传截图失败，请重新上传" andImage:[UIImage imageNamed:@"icon_no.png"] andTipIsBottom:YES];
        });
        for (TaoJinButton *btn in btnArray) {
            btn.enabled =YES;
        }
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
