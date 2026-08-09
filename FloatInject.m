#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

// 存储键
#define kItemsKey      @"FloatInject_items"
#define kLockedKey     @"FloatInject_locked"
#define kIndexKey      @"FloatInject_index"
#define kPosXKey       @"FloatInject_x"
#define kPosYKey       @"FloatInject_y"
#define kTimeoutKey    @"FloatInject_timeout"    // 超时提醒（秒）
#define kCooldownKey   @"FloatInject_cooldown"   // 冷却时间（秒）

// 悬浮窗总高度
#define kFloatHeight   60.0
#define kFloatWidth    40.0

// 默认值
#define kDefaultTimeout   90
#define kDefaultCooldown  2

static UIView *floatView = nil;

// ---- 自定义设置面板 ----
@interface SettingsPanel : UIView <UITextFieldDelegate>
@property (nonatomic, copy) void (^onSave)(NSString *text, BOOL locked, NSInteger timeout, NSInteger cooldown);
@property (nonatomic, copy) void (^onDismiss)(void);
@end

@implementation SettingsPanel {
    UITextField *_itemsField;
    UITextField *_timeoutField;
    UITextField *_cooldownField;
    UISwitch   *_lockSwitch;
    UIView     *_panelContainer;
}

- (instancetype)initWithFrame:(CGRect)frame
                        items:(NSString *)items
                       locked:(BOOL)locked
                      timeout:(NSInteger)timeout
                     cooldown:(NSInteger)cooldown {
    if (self = [super initWithFrame:[UIScreen mainScreen].bounds]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        UITapGestureRecognizer *tapBg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancel)];
        [self addGestureRecognizer:tapBg];

        CGFloat panelW = 290;
        CGFloat panelH = 350;
        _panelContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, panelW, panelH)];
        _panelContainer.center = self.center;
        _panelContainer.backgroundColor = [UIColor whiteColor];
        _panelContainer.layer.cornerRadius = 12;
        _panelContainer.clipsToBounds = YES;
        [self addSubview:_panelContainer];

        // 标题
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 16, panelW-40, 24)];
        title.text = @"悬浮窗设置";
        title.font = [UIFont boldSystemFontOfSize:17];
        title.textAlignment = NSTextAlignmentCenter;
        [_panelContainer addSubview:title];

        CGFloat y = 48;

        // 文字数组
        UILabel *itemsHint = [[UILabel alloc] initWithFrame:CGRectMake(20, y, panelW-40, 14)];
        itemsHint.text = @"文字数组 (标题,内容;…)";
        itemsHint.font = [UIFont systemFontOfSize:12];
        itemsHint.textColor = [UIColor grayColor];
        [_panelContainer addSubview:itemsHint];
        y += 16;

        _itemsField = [[UITextField alloc] initWithFrame:CGRectMake(20, y, panelW-40, 34)];
        _itemsField.borderStyle = UITextBorderStyleRoundedRect;
        _itemsField.font = [UIFont systemFontOfSize:13];
        _itemsField.text = items ?: @"";
        _itemsField.placeholder = @"标题1,内容1;标题2,内容2";
        _itemsField.delegate = self;
        [_panelContainer addSubview:_itemsField];
        y += 42;

        // 超时时间
        UILabel *timeoutLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, panelW-40, 20)];
        timeoutLabel.text = @"超时提醒（秒）";
        timeoutLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:timeoutLabel];
        y += 24;

        _timeoutField = [[UITextField alloc] initWithFrame:CGRectMake(20, y, panelW-40, 34)];
        _timeoutField.borderStyle = UITextBorderStyleRoundedRect;
        _timeoutField.font = [UIFont systemFontOfSize:14];
        _timeoutField.keyboardType = UIKeyboardTypeNumberPad;
        _timeoutField.text = [@(timeout) stringValue];
        _timeoutField.delegate = self;
        [_panelContainer addSubview:_timeoutField];
        y += 42;

        // 冷却时间
        UILabel *cooldownLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, panelW-40, 20)];
        cooldownLabel.text = @"冷却时间（秒）";
        cooldownLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:cooldownLabel];
        y += 24;

        _cooldownField = [[UITextField alloc] initWithFrame:CGRectMake(20, y, panelW-40, 34)];
        _cooldownField.borderStyle = UITextBorderStyleRoundedRect;
        _cooldownField.font = [UIFont systemFontOfSize:14];
        _cooldownField.keyboardType = UIKeyboardTypeNumberPad;
        _cooldownField.text = [@(cooldown) stringValue];
        _cooldownField.delegate = self;
        [_panelContainer addSubview:_cooldownField];
        y += 42;

        // 锁定开关
        UILabel *lockLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 100, 31)];
        lockLabel.text = @"锁定位置";
        lockLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:lockLabel];

        _lockSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(panelW-70, y, 51, 31)];
        _lockSwitch.on = locked;
        [_panelContainer addSubview:_lockSwitch];
        y += 40;

        // 保存按钮
        UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        saveBtn.frame = CGRectMake(20, y, panelW-40, 40);
        [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
        saveBtn.backgroundColor = [UIColor systemBlueColor];
        [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        saveBtn.layer.cornerRadius = 8;
        [saveBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
        [_panelContainer addSubview:saveBtn];

        // 键盘通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)cancel {
    [self dismiss];
    if (self.onDismiss) self.onDismiss();
}

- (void)save {
    [self dismiss];
    NSString *text = _itemsField.text ?: @"";
    BOOL locked = _lockSwitch.on;
    NSInteger timeout = [_timeoutField.text integerValue];
    if (timeout <= 0) timeout = kDefaultTimeout;
    NSInteger cooldown = [_cooldownField.text integerValue];
    if (cooldown <= 0) cooldown = kDefaultCooldown;
    if (self.onSave) self.onSave(text, locked, timeout, cooldown);
}

- (void)dismiss {
    [self endEditing:YES];
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect kbFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat kbTop = self.bounds.size.height - kbFrame.size.height;
    CGFloat panelBottom = _panelContainer.frame.origin.y + _panelContainer.frame.size.height;
    if (panelBottom > kbTop) {
        [UIView animateWithDuration:duration animations:^{
            _panelContainer.center = CGPointMake(self.center.x, kbTop - _panelContainer.frame.size.height/2);
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        _panelContainer.center = self.center;
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

// ---- 悬浮窗视图 ----
@interface FloatView : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *timerLabel;        // 计时小字
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSArray<NSDictionary *> *items;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) NSInteger timeout;          // 超时提醒秒数
@property (nonatomic, assign) NSInteger cooldown;         // 冷却秒数

// 计时相关
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger elapsedSeconds;
@property (nonatomic, assign) BOOL alertPlayed;
@property (nonatomic, assign) NSTimeInterval lastTapTime; // 上次有效点击时间戳
@end

@implementation FloatView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 8;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowRadius = 4;

        // 标题（红色）
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 6, kFloatWidth-8, 16)];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:13];
        _titleLabel.textColor = [UIColor redColor];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.minimumScaleFactor = 0.5;
        [self addSubview:_titleLabel];

        // 内容（蓝色）
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 22, kFloatWidth-8, 16)];
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.font = [UIFont systemFontOfSize:13];
        _contentLabel.textColor = [UIColor blueColor];
        _contentLabel.adjustsFontSizeToFitWidth = YES;
        _contentLabel.minimumScaleFactor = 0.5;
        [self addSubview:_contentLabel];

        // 计时小字（深灰色）
        _timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 40, kFloatWidth-8, 14)];
        _timerLabel.textAlignment = NSTextAlignmentCenter;
        _timerLabel.font = [UIFont systemFontOfSize:6];
        _timerLabel.textColor = [UIColor darkGrayColor];
        _timerLabel.text = @"0";
        [self addSubview:_timerLabel];

        // 手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.8;
        [self addGestureRecognizer:longPress];

        [self reloadFromDefaults];
    }
    return self;
}

- (void)reloadFromDefaults {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    self.locked = [def boolForKey:kLockedKey];
    self.timeout = [def integerForKey:kTimeoutKey];
    if (self.timeout <= 0) self.timeout = kDefaultTimeout;
    self.cooldown = [def integerForKey:kCooldownKey];
    if (self.cooldown <= 0) self.cooldown = kDefaultCooldown;

    // 拖拽手势受锁定影响
    for (UIGestureRecognizer *gr in self.gestureRecognizers) {
        if ([gr isKindOfClass:[UIPanGestureRecognizer class]]) {
            gr.enabled = !self.locked;
        }
    }

    // 文字内容解析
    NSString *itemsString = [def objectForKey:kItemsKey];
    if (!itemsString || itemsString.length == 0) {
        itemsString = @"示例,内容;第二条,信息";
    }
    NSMutableArray *arr = [NSMutableArray array];
    NSArray *groups = [itemsString componentsSeparatedByString:@";"];
    for (NSString *group in groups) {
        NSArray *pair = [group componentsSeparatedByString:@","];
        if (pair.count >= 2) {
            NSString *title = [pair[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *content = [pair[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [arr addObject:@{@"title":title ?: @"", @"content":content ?: @""}];
        }
    }
    self.items = arr;

    self.currentIndex = [def integerForKey:kIndexKey];
    if (self.currentIndex < 0 || self.currentIndex >= self.items.count) {
        self.currentIndex = 0;
    }

    // 位置恢复
    CGFloat x = [def doubleForKey:kPosXKey];
    CGFloat y = [def doubleForKey:kPosYKey];
    if (x == 0 && y == 0) {
        x = ([UIScreen mainScreen].bounds.size.width - kFloatWidth) / 2;
        y = ([UIScreen mainScreen].bounds.size.height - kFloatHeight) / 2;
    }
    self.frame = CGRectMake(x, y, kFloatWidth, kFloatHeight);
    [self updateLabels];

    // 计时器初始状态：不自动启动，等点击后才开始
    [self stopTimer];
    self.elapsedSeconds = 0;
    self.alertPlayed = NO;
    self.timerLabel.text = @"0";
}

- (void)updateLabels {
    if (self.items.count == 0) {
        self.titleLabel.text = @"";
        self.contentLabel.text = @"";
        return;
    }
    NSDictionary *item = self.items[self.currentIndex];
    self.titleLabel.text = item[@"title"];
    self.contentLabel.text = item[@"content"];
}

// 点击处理（含冷却判断）
- (void)handleTap:(UITapGestureRecognizer *)tap {
    // 冷却时间检查
    NSTimeInterval now = CACurrentMediaTime();
    if (self.lastTapTime > 0 && (now - self.lastTapTime) < self.cooldown) {
        return; // 忽略冷却内的点击
    }
    self.lastTapTime = now;

    // 切换显示内容
    if (self.items.count > 0) {
        self.currentIndex = (self.currentIndex + 1) % self.items.count;
        [self updateLabels];
        [[NSUserDefaults standardUserDefaults] setInteger:self.currentIndex forKey:kIndexKey];
    }

    // 重置计时
    [self resetTimer];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if (self.locked) return;
    CGPoint translation = [pan translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x,
                                    self.center.y + translation.y);
    CGFloat margin = 20;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    newCenter.x = MAX(self.bounds.size.width/2 + margin, newCenter.x);
    newCenter.x = MIN(screenSize.width - self.bounds.size.width/2 - margin, newCenter.x);
    newCenter.y = MAX(self.bounds.size.height/2 + margin, newCenter.y);
    newCenter.y = MIN(screenSize.height - self.bounds.size.height/2 - margin, newCenter.y);
    self.center = newCenter;
    [pan setTranslation:CGPointZero inView:self.superview];

    if (pan.state == UIGestureRecognizerStateEnded) {
        [[NSUserDefaults standardUserDefaults] setDouble:self.frame.origin.x forKey:kPosXKey];
        [[NSUserDefaults standardUserDefaults] setDouble:self.frame.origin.y forKey:kPosYKey];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;

    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [gen impactOccurred];
    }

    NSString *currentItems = [[NSUserDefaults standardUserDefaults] objectForKey:kItemsKey];
    if (!currentItems) currentItems = @"示例,内容;第二条,信息";
    NSInteger currentTimeout = self.timeout;
    NSInteger currentCooldown = self.cooldown;
    BOOL currentLocked = self.locked;

    __weak typeof(self) weakSelf = self;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;

    SettingsPanel *panel = [[SettingsPanel alloc] initWithFrame:keyWindow.bounds
                                                          items:currentItems
                                                         locked:currentLocked
                                                        timeout:currentTimeout
                                                       cooldown:currentCooldown];
    panel.onSave = ^(NSString *text, BOOL locked, NSInteger timeout, NSInteger cooldown) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        [def setObject:text forKey:kItemsKey];
        [def setBool:locked forKey:kLockedKey];
        [def setInteger:timeout forKey:kTimeoutKey];
        [def setInteger:cooldown forKey:kCooldownKey];
        [def synchronize];
        [strongSelf reloadFromDefaults];
    };
    panel.onDismiss = ^{};

    panel.alpha = 0;
    [keyWindow addSubview:panel];
    [UIView animateWithDuration:0.25 animations:^{
        panel.alpha = 1;
    }];
}

// ---- 计时器管理 ----
- (void)resetTimer {
    [self stopTimer];
    self.elapsedSeconds = 0;
    self.alertPlayed = NO;
    self.timerLabel.text = @"0";
    [self startTimer];
}

- (void)startTimer {
    if (self.timer) return;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(timerTick)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)timerTick {
    self.elapsedSeconds++;
    self.timerLabel.text = [NSString stringWithFormat:@"%ld", (long)self.elapsedSeconds];

    // 超时提醒
    if (self.elapsedSeconds >= self.timeout && !self.alertPlayed) {
        self.alertPlayed = YES;
        // 播放短信提示音 (1007)
        AudioServicesPlaySystemSound(1007);
    }
}

- (void)dealloc {
    [self stopTimer];
}

@end

// ---- 注入入口 ----
__attribute__((constructor))
static void injectFloatingView(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (floatView) return;

        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        CGFloat x = [def doubleForKey:kPosXKey];
        CGFloat y = [def doubleForKey:kPosYKey];
        if (x == 0 && y == 0) {
            x = ([UIScreen mainScreen].bounds.size.width - kFloatWidth) / 2;
            y = ([UIScreen mainScreen].bounds.size.height - kFloatHeight) / 2;
        }

        FloatView *fv = [[FloatView alloc] initWithFrame:CGRectMake(x, y, kFloatWidth, kFloatHeight)];
        floatView = fv;

        void (^addToWindow)(void) = ^{
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (keyWindow) {
                [keyWindow addSubview:fv];
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication].keyWindow addSubview:fv];
                });
            }
        };

        if ([NSThread isMainThread]) {
            addToWindow();
        } else {
            dispatch_async(dispatch_get_main_queue(), addToWindow);
        }
    });
}