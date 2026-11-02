#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>

static BOOL gAutoImport = NO;
static UIImage *gFirstImage = nil;

@interface SAPanel : UIView
@property (nonatomic, strong) UIView *body;
@property (nonatomic, strong) UIButton *head, *scan;
@end

@implementation SAPanel
- (instancetype)init {
  self = [super initWithFrame:CGRectMake(20, 120, 170, 130)];
  self.backgroundColor = UIColor.blackColor;
  self.layer.cornerRadius = 12;
  self.layer.borderColor = UIColor.whiteColor.CGColor;
  self.layer.borderWidth = 1;
  self.clipsToBounds = YES;

  _head = [UIButton buttonWithType:UIButtonTypeSystem];
  _head.frame = CGRectMake(0, 0, 170, 36);
  [_head setTitle:@"▾ Star Auto" forState:UIControlStateNormal];
  [_head setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  [_head addTarget:self action:@selector(fold) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:_head];

  _body = [[UIView alloc] initWithFrame:CGRectMake(0, 36, 170, 94)];
  UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 95, 30)];
  l.text = @"Auto nhập ảnh"; l.textColor = UIColor.whiteColor;
  l.font = [UIFont systemFontOfSize:13];
  UISwitch *s = [UISwitch new];
  s.frame = CGRectMake(108, 11, 51, 31);
  s.onTintColor = UIColor.whiteColor; s.thumbTintColor = UIColor.grayColor;
  [s addTarget:self action:@selector(tog:) forControlEvents:UIControlEventValueChanged];

  _scan = [UIButton buttonWithType:UIButtonTypeSystem];
  _scan.frame = CGRectMake(12, 52, 146, 30);
  [_scan setTitle:@"Quét class" forState:UIControlStateNormal];
  [_scan setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
  _scan.backgroundColor = UIColor.whiteColor;
  _scan.layer.cornerRadius = 8;
  [_scan addTarget:self action:@selector(doScan) forControlEvents:UIControlEventTouchUpInside];

  [_body addSubview:l]; [_body addSubview:s]; [_body addSubview:_scan];
  [self addSubview:_body];
  [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)]];
  return self;
}
- (void)fold {
  BOOL c = !_body.hidden; _body.hidden = c;
  CGRect f = self.frame; f.size.height = c ? 36 : 130;
  [UIView animateWithDuration:.2 animations:^{ self.frame = f; }];
  [_head setTitle:c ? @"▸ Star Auto" : @"▾ Star Auto" forState:UIControlStateNormal];
}
- (void)tog:(UISwitch *)s { gAutoImport = s.on; }
- (void)drag:(UIPanGestureRecognizer *)g {
  CGPoint t = [g translationInView:self.superview];
  self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
  [g setTranslation:CGPointZero inView:self.superview];
}
- (void)doScan {
  unsigned int n = 0;
  const char **names = objc_copyClassNamesForImage(_dyld_get_image_name(0), &n);
  NSArray *keys = @[@"layer", @"import", @"picker", @"photo", @"asset", @"media", @"gallery"];
  NSMutableArray *out = [NSMutableArray array];
  for (unsigned int i = 0; i < n; i++) {
    NSString *c = @(names[i]);
    for (NSString *k in keys)
      if ([c.lowercaseString containsString:k]) { [out addObject:c]; break; }
  }
  free(names);
  UIPasteboard.generalPasteboard.string = [out componentsJoinedByString:@"\n"];
  [_scan setTitle:[NSString stringWithFormat:@"Đã copy %lu class", (unsigned long)out.count]
         forState:UIControlStateNormal];
}
@end

%ctor {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                 dispatch_get_main_queue(), ^{
    UIWindow *w = nil;
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes)
      if ([sc isKindOfClass:UIWindowScene.class]) { w = ((UIWindowScene *)sc).windows.firstObject; break; }
    [w addSubview:[SAPanel new]];
  });
}
