//
//  RootNavigationController.m
//  MiAiApp
//
//  Created by 徐阳 on 2017/5/18.
//  Copyright © 2017年 徐阳. All rights reserved.
//

#import "RootNavigationController.h"
#import "XYTransitionProtocol.h"
#import "XYTransition.h"

@interface RootNavigationController ()<UINavigationControllerDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, weak) id popDelegate;
@property (nonatomic,strong) UIPercentDrivenInteractiveTransition *interactivePopTransition;
@property (nonatomic,strong) UIScreenEdgePanGestureRecognizer *popRecognizer;
//@property (nonatomic,strong) UIPanGestureRecognizer *popRecognizer;
PropertyBool(isCanSlidBack);//是否可以滑动返回

@end

@implementation RootNavigationController

//APP生命周期中 只会执行一次
+ (void)initialize
{
    //导航栏主题 title文字属性
    UINavigationBar *navBar = [UINavigationBar appearance];
    //导航栏背景图
//    [navBar setBackgroundImage:[UIImage imageNamed:@"tabBarBj"] forBarMetrics:UIBarMetricsDefault];
    [navBar setBarTintColor:CNavBgColor];
    [navBar setTintColor:KWhiteColor];
    [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName :KWhiteColor, NSFontAttributeName : [UIFont systemFontOfSize:18]}];
    
    //导航栏左右文字主题
    UIBarButtonItem *barButtonItem = [UIBarButtonItem appearance];
    
//    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName : KWhiteColor, NSFontAttributeName : [UIFont systemFontOfSize:12]} forState:UIControlStateNormal];
    
//    //tabBar主题 title文字属性
//    UITabBarItem *tabBarItem = [UITabBarItem appearance];
//    [tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName : GRAYTEXTCOLOR} forState:UIControlStateNormal];
//    [tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName : ButtonNormalColor} forState:UIControlStateSelected];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.popDelegate = self.interactivePopGestureRecognizer.delegate;
    self.delegate = self;
    //navigationBar样式设置
//    self.navigationBar.barTintColor = KBlueColor;
//    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : KWhiteColor, NSFontAttributeName : [UIFont boldSystemFontOfSize:16]}];
//    [self.navigationBar setTintColor:KWhiteColor];    // Do any additional setup after loading the view.

    _popRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self.popDelegate action:@selector(handleNavigationTransition:)];
    _popRecognizer.edges = UIRectEdgeLeft;
    _popRecognizer.delegate = self;
    [self.view addGestureRecognizer:_popRecognizer];
}

//解决手势失效问题
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController == self.viewControllers[0]) {
        self.interactivePopGestureRecognizer.delegate = self.popDelegate;
    }else{
        self.interactivePopGestureRecognizer.delegate = nil;
    }
}

//push时隐藏tabbar
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.viewControllers.count > 0) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    [super pushViewController:viewController animated:animated];
}

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    
    if ([viewController isKindOfClass:[RootViewController class]]) {
        RootViewController * vc = (RootViewController *)viewController;
        if (vc.isHidenNaviBar) {
            [vc.navigationController setNavigationBarHidden:YES animated:animated];
        }else{
            [vc.navigationController setNavigationBarHidden:NO animated:animated];
        }
    }
}

/**
 *  返回到指定的类视图
 *
 *  @param ClassName 类名
 *  @param animated  是否动画
 */
-(BOOL)popToAppointViewController:(NSString *)ClassName animated:(BOOL)animated
{
    id vc = [self getCurrentViewControllerClass:ClassName];
    if(vc != nil && [vc isKindOfClass:[UIViewController class]])
    {
        [self popToViewController:vc animated:animated];
        return YES;
    }
    
    return NO;
}

/*!
 *  获得当前导航器显示的视图
 *
 *  @param ClassName 要获取的视图的名称
 *
 *  @return 成功返回对应的对象，失败返回nil;
 */
-(instancetype)getCurrentViewControllerClass:(NSString *)ClassName
{
    Class classObj = NSClassFromString(ClassName);
    
    NSArray * szArray =  self.viewControllers;
    for (id vc in szArray) {
        if([vc isMemberOfClass:classObj])
        {
            return vc;
        }
    }
    
    return nil;
}


-(UIViewController *)childViewControllerForStatusBarStyle{
    return self.topViewController;
}


#pragma mark ————— 转场动画区 —————

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}

-(void)setIsCanSlidBack:(BOOL)isCanSlidBack{
    _isCanSlidBack = isCanSlidBack;
}

#pragma mark -UIViewControllerAnimatedTransitioning
//navigation切换是会走这个代理
-(id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if ([fromVC conformsToProtocol:@protocol(XYTransitionProtocol)] && [toVC conformsToProtocol:@protocol(XYTransitionProtocol)]) {
        
        BOOL pinterestNedd = [self isNeedTransition:fromVC:toVC];
        XYTransition *transion = [XYTransition new];
        if (operation == UINavigationControllerOperationPush && pinterestNedd) {
            transion.isPush = YES;
        }
        else if(operation == UINavigationControllerOperationPop && pinterestNedd)
        {
            transion.isPush = NO;
        }
        else{
            return nil;
        }
        return transion;
    }
    return nil;
}

//判断fromVC和toVC是否需要实现pinterest效果
-(BOOL)isNeedTransition:(UIViewController<XYTransitionProtocol> *)fromVC :(UIViewController<XYTransitionProtocol> *)toVC
{
    BOOL a = NO;
    BOOL b = NO;
    if ([fromVC respondsToSelector:@selector(isNeedTransition)] && [fromVC isNeedTransition]) {
        a = YES;
    }
    if ([toVC respondsToSelector:@selector(isNeedTransition)] && [toVC isNeedTransition]) {
        b = YES;
    }
    return (a && b) ;
    
}

#pragma mark -- NavitionContollerDelegate
- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    if (!self.interactivePopTransition) { return nil; }
    return self.interactivePopTransition;
}


#pragma mark UIGestureRecognizer handlers

- (void)handleNavigationTransition:(UIScreenEdgePanGestureRecognizer*)recognizer
{
    CGFloat progress = [recognizer translationInView:self.navigationController.view].x / (self.navigationController.view.bounds.size.width);
    progress = MIN(1.0, MAX(0.0, progress));
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.interactivePopTransition = [[UIPercentDrivenInteractiveTransition alloc] init];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self.interactivePopTransition updateInteractiveTransition:progress];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGPoint velocity = [recognizer velocityInView:recognizer.view];
        
        if (progress > 0.5 || velocity.x >1000) {
            [self.interactivePopTransition finishInteractiveTransition];
        }
        else {
            [self.interactivePopTransition cancelInteractiveTransition];
        }
        self.interactivePopTransition = nil;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end