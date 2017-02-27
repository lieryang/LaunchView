//
//  EYLaunchView.m
//  LaunchViewDemo
//
//  Created by lieryang on 2017/1/29.
//  Copyright © 2017年 lieryang. All rights reserved.
//

#define kScreen_height [[UIScreen mainScreen] bounds].size.height
#define kScreen_width  [[UIScreen mainScreen] bounds].size.width

#import "EYLaunchView.h"

static NSString *const CFBundleShortVersionString = @"CFBundleShortVersionString";
@interface EYLaunchView () <UIScrollViewDelegate>

/** 滚动视图 */
@property (weak, nonatomic) UIScrollView  *launchScrollView;

/** 小圆点 */
@property (strong, nonatomic) UIPageControl *page;

@end
@implementation EYLaunchView
NSArray *images;
BOOL isScrollOut;//在最后一页再次滑动是否隐藏引导页
CGRect enterButtonFrame;
NSString *enterBtnImage;
static EYLaunchView *launch = nil;
#pragma mark - 创建对象-->>不带button
+(instancetype)sharedWithImages:(NSArray *)imageNames
{
    images = imageNames;
    isScrollOut = YES;
    launch = [[self alloc] initWithFrame:CGRectMake(0, 0, kScreen_width, kScreen_height)];
    launch.backgroundColor = [UIColor whiteColor];
    return launch;
}

#pragma mark - 创建对象-->>带button
+(instancetype)sharedWithImages:(NSArray *)imageNames buttonImage:(NSString *)buttonImageName buttonFrame:(CGRect)frame
{
    images = imageNames;
    isScrollOut = NO;
    enterButtonFrame = frame;
    enterBtnImage = buttonImageName;
    launch = [[self alloc] initWithFrame:CGRectMake(0, 0, kScreen_width, kScreen_height)];
    launch.backgroundColor = [UIColor whiteColor];
    return launch;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self addObserver:self forKeyPath:@"currentColor" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"nomalColor" options:NSKeyValueObservingOptionNew context:nil];
        if ([self ey_isFirstLauch])
        {
            UIWindow *window = [[UIApplication sharedApplication] windows].lastObject;
            [window addSubview:self];
            [self ey_createScrollView];
        }else
        {
            [self removeFromSuperview];
        }
    }
    return self;
}
#pragma mark - 判断是不是首次登录或者版本更新
-(BOOL)ey_isFirstLauch
{
    //获取上次启动应用保存版本
    NSString *lastAppShortVersionString = [[NSUserDefaults standardUserDefaults] objectForKey:CFBundleShortVersionString];
    
    //获取当前版本号
    NSString * currentAppShortVersionString = [[NSBundle mainBundle] infoDictionary][CFBundleShortVersionString];
    
    //首次登录、版本升级
    if (lastAppShortVersionString == nil || [lastAppShortVersionString compare:currentAppShortVersionString] == NSOrderedAscending)
    {
        [[NSUserDefaults standardUserDefaults] setObject:currentAppShortVersionString forKey:CFBundleShortVersionString];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }else
    {
        return NO;
    }
}
#pragma mark - 创建滚动视图
-(void)ey_createScrollView
{
    UIScrollView * launchScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreen_width, kScreen_height)];
    launchScrollView.showsHorizontalScrollIndicator = NO;
    launchScrollView.bounces = NO;
    launchScrollView.pagingEnabled = YES;
    launchScrollView.delegate = self;
    launchScrollView.contentSize = CGSizeMake(kScreen_width * images.count, kScreen_height);
    self.launchScrollView = launchScrollView;
    [self addSubview:launchScrollView];
    
    for (int i = 0; i < images.count; i ++)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i * kScreen_width, 0, kScreen_width, kScreen_height)];
        NSString * imageNameNoType = [images[i] stringByDeletingPathExtension];
        NSString * type = [images[i] pathExtension];
        UIImage * image;
        if (type.length == 0)
        {
            image = [UIImage imageNamed:imageNameNoType];
        }else
        {
            NSString * imagePath = [[NSBundle mainBundle] pathForResource:imageNameNoType ofType:type];
            image = [UIImage imageWithContentsOfFile:imagePath];
            if (image == nil)
            {
                image = [UIImage imageNamed:imageNameNoType];
            }
        }
        
        imageView.image = image;
        [launchScrollView addSubview:imageView];
        if (i == images.count - 1)
        {
            //判断要不要添加button
            if (!isScrollOut)
            {
                UIButton *enterButton = [[UIButton alloc] initWithFrame:CGRectMake(enterButtonFrame.origin.x, enterButtonFrame.origin.y, enterButtonFrame.size.width, enterButtonFrame.size.height)];
                [enterButton setImage:[UIImage imageNamed:enterBtnImage] forState:UIControlStateNormal];
                [enterButton addTarget:self action:@selector(ey_tapEnterButton) forControlEvents:UIControlEventTouchUpInside];
                [imageView addSubview:enterButton];
                imageView.userInteractionEnabled = YES;
            }
        }
    }
    
    UIPageControl * page = [[UIPageControl alloc] initWithFrame:CGRectMake(0, kScreen_height - 50, kScreen_width, 30)];
    page.numberOfPages = images.count;
    page.backgroundColor = [UIColor clearColor];
    page.currentPage = 0;
    page.defersCurrentPageDisplay = YES;
    self.page = page;
    [self addSubview:page];
}
#pragma mark - 进入按钮
-(void)ey_tapEnterButton
{
    [self ey_hideGuidView];
}
#pragma mark - 隐藏引导页
-(void)ey_hideGuidView
{
    [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self removeFromSuperview];
        });
    }];
}
#pragma mark - scrollView Delegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //当前的下标
    int cuttentIndex = (int)(scrollView.contentOffset.x + kScreen_width/2)/kScreen_width;
    if (cuttentIndex == images.count - 1)
    {
        if ([self ey_isScrolltoLeft:scrollView])
        {
            if (!isScrollOut)
            {
                return;
            }
            //隐藏引导页
            [self ey_hideGuidView];
        }
    }
}
#pragma mark - 改变小圆点的位置
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.launchScrollView)
    {
        int cuttentIndex = (int)(scrollView.contentOffset.x + kScreen_width/2)/kScreen_width;
        self.page.currentPage = cuttentIndex;
    }
}
#pragma mark - 判断滚动方向
-(BOOL)ey_isScrolltoLeft:(UIScrollView *) scrollView
{
    //返回YES为向左反动，NO为右滚动
    if ([scrollView.panGestureRecognizer translationInView:scrollView.superview].x < 0)
    {
        return YES;
    }else
    {
        return NO;
    }
}
#pragma mark - KVO监测值的变化
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentColor"])
    {
        self.page.currentPageIndicatorTintColor = self.currentColor;
    }
    if ([keyPath isEqualToString:@"nomalColor"])
    {
        self.page.pageIndicatorTintColor = self.nomalColor;
    }
}
@end
