#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <AVFoundation/AVFoundation.h>

static BOOL gAutoImport = NO;
static BOOL gAutoBeat = NO;
static UIWindow *gWindow = nil;

@interface PainuzzPanel : UIView
@property (nonatomic, strong) UIView *body;
@property (nonatomic, strong) UIButton *head, *scanBtn;
@property (nonatomic, assign) BOOL isCollapsed;
@end

@implementation PainuzzPanel

- (instancetype)init {
    CGFloat px = [[NSUserDefaults standardUserDefaults] floatForKey:@"pz_x"];
    CGFloat py = [[NSUserDefaults standardUserDefaults] floatForKey:@"pz_y"];
    if (px <= 0 || py <= 0) { px = 16; py = 120; }

    self = [super initWithFrame:CGRectMake(px, py, 260, 195)];
    if (!self) return nil;
    
    self.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.94];
    self.layer.cornerRadius = 16;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 1.2;
    self.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.layer.shadowRadius = 12;
    self.layer.shadowOpacity = 0.8;
    self.layer.shadowOffset = CGSizeZero;

    _head = [UIButton buttonWithType:UIButtonTypeSystem];
    _head.frame = CGRectMake(0, 0, 260, 44);
    _head.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [_head setTitle:@"◆ PAINUZZ TOOL" forState:UIControlStateNormal];
    [_head setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_head addTarget:self action:@selector(fold) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_head];

    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(12, 44, 236, 1)];
    line.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    [self addSubview:line];

    _body = [[UIView alloc] initWithFrame:CGRectMake(0, 44, 260, 151)];
    
    UILabel *l1 = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, 150, 30)];
    l1.text = @"Auto Nhập Ảnh"; l1.textColor = UIColor.whiteColor;
    l1.font = [UIFont systemFontOfSize:13.5 weight:UIFontWeightMedium];
    UISwitch *s1 = [[UISwitch alloc] initWithFrame:CGRectMake(190, 11, 51, 31)];
    s1.onTintColor = UIColor.whiteColor; s1.thumbTintColor = UIColor.blackColor;
    s1.tag = 1;
    s1.transform = CGAffineTransformMakeScale(0.85, 0.85);
    s1.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"pz_img"];
    gAutoImport = s1.on;
    [s1 addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
    [_body addSubview:l1]; [_body addSubview:s1];

    UILabel *l2 = [[UILabel alloc] initWithFrame:CGRectMake(16, 52, 150, 30)];
    l2.text = @"Auto Cắt Nhạc"; l2.textColor = UIColor.whiteColor;
    l2.font = [UIFont systemFontOfSize:13.5 weight:UIFontWeightMedium];
    UISwitch *s2 = [[UISwitch alloc] initWithFrame:CGRectMake(190, 51, 51, 31)];
    s2.onTintColor = UIColor.whiteColor; s2.thumbTintColor = UIColor.blackColor;
    s2.tag = 2;
    s2.transform = CGAffineTransformMakeScale(0.85, 0.85);
    s2.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"pz_beat"];
    gAutoBeat = s2.on;
    [s2 addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
    [_body addSubview:l2]; [_body addSubview:s2];

    _scanBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _scanBtn.frame = CGRectMake(16, 100, 228, 34);
    [_scanBtn setTitle:@"Quét Class (Copy)" forState:UIControlStateNormal];
    [_scanBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _scanBtn.backgroundColor = [UIColor whiteColor];
    _scanBtn.layer.cornerRadius = 8;
    _scanBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [_scanBtn addTarget:self action:@selector(doScan) forControlEvents:UIControlEventTouchUpInside];
    [_body addSubview:_scanBtn];

    [self addSubview:_body];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [_head addGestureRecognizer:pan];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pz_collapsed"]) {
        self.isCollapsed = YES;
        [self fold];
    }
    
    return self;
}

- (void)fold {
    self.isCollapsed = !self.isCollapsed;
    _body.hidden = self.isCollapsed;
    CGRect f = self.frame;
    f.size.height = self.isCollapsed ? 44 : 195;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = f;
    }];
    [_head setTitle:(self.isCollapsed ? @"◆ PAINUZZ" : @"◆ PAINUZZ TOOL") forState:UIControlStateNormal];
    
    [[NSUserDefaults standardUserDefaults] setBool:self.isCollapsed forKey:@"pz_collapsed"];
}

- (void)toggleSwitch:(UISwitch *)s {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if (s.tag == 1) { gAutoImport = s.on; [d setBool:s.on forKey:@"pz_img"]; }
    if (s.tag == 2) { gAutoBeat = s.on; [d setBool:s.on forKey:@"pz_beat"]; }
    [d synchronize];
}

- (void)drag:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    [g setTranslation:CGPointZero inView:self.superview];
    
    if (g.state == UIGestureRecognizerStateEnded) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d setFloat:self.frame.origin.x forKey:@"pz_x"];
        [d setFloat:self.frame.origin.y forKey:@"pz_y"];
        [d synchronize];
    }
}

- (void)doScan {
    unsigned int n = 0;
    const char **names = objc_copyClassNamesForImage(_dyld_get_image_name(0), &n);
    NSArray *keys = @[@"vs", @"editor", @"image", @"picker", @"photo", @"asset", @"media", @"gallery", @"scene", @"audio", @"song", @"beat", @"split"];
    NSMutableArray *out = [NSMutableArray array];
    
    for (unsigned int i = 0; i < n; i++) {
        NSString *c = @(names[i]);
        NSString *lowerC = c.lowercaseString;
        for (NSString *k in keys) {
            if ([lowerC containsString:k]) {
                [out addObject:c];
                break;
            }
        }
    }
    free(names);
    
    NSArray *sorted = [out sortedArrayUsingSelector:@selector(compare:)];
    UIPasteboard.generalPasteboard.string = [sorted componentsJoinedByString:@"\n"];
    
    [_scanBtn setTitle:[NSString stringWithFormat:@"Đã copy %lu class!", (unsigned long)sorted.count] forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self->_scanBtn setTitle:@"Quét Class (Copy)" forState:UIControlStateNormal];
    });
}

@end

static void FillEmptyImageViews(UIImage *img, UIView *root) {
    if (!root) return;
    if ([root isKindOfClass:[UIImageView class]]) {
        UIImageView *iv = (UIImageView *)root;
        if (iv.image == nil || iv.image.size.width <= 1) {
            iv.image = img;
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
        }
    }
    for (UIView *sub in root.subviews) {
        FillEmptyImageViews(img, sub);
    }
}

static NSArray<NSNumber *> *DetectBeats(NSURL *url) {
    if (!url) return @[];
    NSError *err = nil;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:url error:&err];
    if (!file || err) return @[];
    AVAudioPCMBuffer *buf = [[AVAudioPCMBuffer alloc] initWithPCMFormat:file.processingFormat frameCapacity:(AVAudioFrameCount)file.length];
    if (![file readIntoBuffer:buf error:&err]) return @[];

    float *s = buf.floatChannelData[0];
    NSUInteger n = buf.frameLength;
    double sr = file.processingFormat.sampleRate;
    if (n == 0 || sr <= 0) return @[];

    const NSUInteger hop = (NSUInteger)(sr * 0.010);
    const NSUInteger win = (NSUInteger)(sr * 0.020);
    NSUInteger cnt = (n - win) / hop + 1;
    
    float *en = calloc(cnt, sizeof(float));
    for (NSUInteger i = 0; i < cnt; i++) {
        float sum = 0; NSUInteger st = i * hop;
        for (NSUInteger j = 0; j < win; j++) { float v = s[st + j]; sum += v * v; }
        en[i] = sum / (float)win;
    }

    float *flux = calloc(cnt, sizeof(float));
    for (NSUInteger i = 1; i < cnt; i++) {
        float d = en[i] - en[i - 1];
        flux[i] = d > 0 ? d : 0;
    }
    free(en);

    NSMutableArray *beats = [NSMutableArray array];
    double last = -10.0;
    for (NSUInteger i = 15; i < cnt; i++) {
        float avg = 0;
        for (NSUInteger k = i - 15; k < i; k++) avg += flux[k];
        avg /= 15.0;
        if (flux[i] > avg * 1.55f && flux[i] > 1e-6f) {
            double t = (double)(i * hop) / sr;
            if (t - last >= 0.14) { [beats addObject:@(t)]; last = t; }
        }
    }
    free(flux);
    return beats;
}

%hook UIImagePickerController
- (void)imagePickerController:(UIImagePickerController *)p didFinishPickingMediaWithInfo:(NSDictionary *)info {
    %orig;
    if (!gAutoImport) return;
    
    UIImage *picked = info[UIImagePickerControllerOriginalImage];
    if (!picked) return;
    
    UIView *root = p.presentingViewController.view ?: gWindow.rootViewController.view;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        FillEmptyImageViews(picked, root);
    });
}
%end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (gWindow) [gWindow makeKeyAndVisible];
}
%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        gWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        gWindow.windowLevel = UIWindowLevelAlert + 2000;
        gWindow.backgroundColor = [UIColor clearColor];
        gWindow.rootViewController = [UIViewController new];
        gWindow.rootViewController.view.backgroundColor = [UIColor clearColor];
        gWindow.hidden = NO;
        
        [gWindow.rootViewController.view addSubview:[PainuzzPanel new]];
    });
}