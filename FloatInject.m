#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

// ===== 导入触摸模拟所需头文件 =====
#import "UITouch-KIFAdditions.h"
#import "UIEvent+KIFAdditions.h"
#import "UIApplication-KIFAdditions.h"

// 存储键
#define kItemsKey           @"FloatInject_items"
#define kLockedKey          @"FloatInject_locked"
#define kIndexKey           @"FloatInject_index"
#define kPosXKey            @"FloatInject_x"
#define kPosYKey            @"FloatInject_y"
#define kTimeoutKey         @"FloatInject_timeout"
#define kCooldownKey        @"FloatInject_cooldown"
#define kPausedKey          @"FloatInject_paused"
#define kBarkEnabledKey     @"FloatInject_bark_enabled"
#define kBarkKeyKey         @"FloatInject_bark_key"
#define kCountdownKey       @"FloatInject_countdown_min"
#define kCloseAppKey        @"FloatInject_close_app"
#define kCountdownStartKey  @"FloatInject_countdown_start"
#define kClickXKey          @"FloatInject_click_x"
#define kClickYKey          @"FloatInject_click_y"
#define kDelayKey           @"FloatInject_delay"

// 悬浮窗尺寸
#define kFloatWidth    38.0
#define kFloatHeight   50.0

// 默认值
#define kDefaultTimeout      120
#define kDefaultCooldown     2
#define kDefaultCountdownMin 40
#define kDefaultCloseApp     NO
#define kDefaultClickX       390.0
#define kDefaultClickY       390.0
#define kDefaultDelay        8.0

static UIView *floatView = nil;

// ---- 自定义设置面板（新增延迟输入） ----
@interface SettingsPanel : UIView <UITextFieldDelegate>
@property (nonatomic, copy) void (^onSave)(NSString *text, BOOL locked, NSInteger timeout, NSInteger cooldown, BOOL barkEnabled, NSString *barkKey, NSInteger countdownMin, BOOL closeApp, CGFloat clickX, CGFloat clickY, CGFloat delay);
@property (nonatomic, copy) void (^onDismiss)(void);
@end

@implementation SettingsPanel {
    UITextField *_itemsField;
    UITextField *_timeoutField;
    UITextField *_cooldownField;
    UITextField *_barkKeyField;
    UITextField *_countdownField;
    UITextField *_clickXField;
    UITextField *_clickYField;
    UITextField *_delayField;
    UISwitch   *_lockSwitch;
    UISwitch   *_barkSwitch;
    UISwitch   *_closeAppSwitch;
    UIView     *_panelContainer;
}

- (instancetype)initWithFrame:(CGRect)frame
                        items:(NSString *)items
                       locked:(BOOL)locked
                      timeout:(NSInteger)timeout
                     cooldown:(NSInteger)cooldown
                  barkEnabled:(BOOL)barkEnabled
                      barkKey:(NSString *)barkKey
                 countdownMin:(NSInteger)countdownMin
                     closeApp:(BOOL)closeApp
                      clickX:(CGFloat)clickX
                      clickY:(CGFloat)clickY
                       delay:(CGFloat)delay {
    if (self = [super initWithFrame:[UIScreen mainScreen].bounds]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        UITapGestureRecognizer *tapBg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancel)];
        [self addGestureRecognizer:tapBg];

        CGFloat panelW = 290;
        CGFloat panelH = 620;
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

        // 倒计时分钟数
        UILabel *countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, panelW-40, 20)];
        countdownLabel.text = @"暂停倒计时（分钟）";
        countdownLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:countdownLabel];
        y += 24;

        _countdownField = [[UITextField alloc] initWithFrame:CGRectMake(20, y, panelW-40, 34)];
        _countdownField.borderStyle = UITextBorderStyleRoundedRect;
        _countdownField.font = [UIFont systemFontOfSize:14];
        _countdownField.keyboardType = UIKeyboardTypeNumberPad;
        _countdownField.text = [@(countdownMin) stringValue];
        _countdownField.delegate = self;
        [_panelContainer addSubview:_countdownField];
        y += 42;

        // 点击坐标 X
        UILabel *clickXLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 80, 20)];
        clickXLabel.text = @"点击 X:";
        clickXLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:clickXLabel];
        _clickXField = [[UITextField alloc] initWithFrame:CGRectMake(110, y-2, 70, 30)];
        _clickXField.borderStyle = UITextBorderStyleRoundedRect;
        _clickXField.font = [UIFont systemFontOfSize:14];
        _clickXField.keyboardType = UIKeyboardTypeDecimalPad;
        _clickXField.text = [NSString stringWithFormat:@"%.0f", clickX];
        _clickXField.delegate = self;
        [_panelContainer addSubview:_clickXField];

        // 点击坐标 Y
        UILabel *clickYLabel = [[UILabel alloc] initWithFrame:CGRectMake(190, y, 80, 20)];
        clickYLabel.text = @"Y:";
        clickYLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:clickYLabel];
        _clickYField = [[UITextField alloc] initWithFrame:CGRectMake(220, y-2, 50, 30)];
        _clickYField.borderStyle = UITextBorderStyleRoundedRect;
        _clickYField.font = [UIFont systemFontOfSize:14];
        _clickYField.keyboardType = UIKeyboardTypeDecimalPad;
        _clickYField.text = [NSString stringWithFormat:@"%.0f", clickY];
        _clickYField.delegate = self;
        [_panelContainer addSubview:_clickYField];
        y += 40;

        // 延迟秒数
        UILabel *delayLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 100, 20)];
        delayLabel.text = @"延迟（秒）:";
        delayLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:delayLabel];
        _delayField = [[UITextField alloc] initWithFrame:CGRectMake(130, y-2, 60, 30)];
        _delayField.borderStyle = UITextBorderStyleRoundedRect;
        _delayField.font = [UIFont systemFontOfSize:14];
        _delayField.keyboardType = UIKeyboardTypeDecimalPad;
        _delayField.text = [NSString stringWithFormat:@"%.1f", delay];
        _delayField.delegate = self;
        [_panelContainer addSubview:_delayField];
        y += 40;

        // 锁定开关
        UILabel *lockLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 100, 31)];
        lockLabel.text = @"锁定位置";
        lockLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:lockLabel];

        _lockSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(panelW-70, y, 51, 31)];
        _lockSwitch.on = locked;
        [_panelContainer addSubview:_lockSwitch];
        y += 40;

        // Bark 推送开关
        UILabel *barkSwitchLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 100, 31)];
        barkSwitchLabel.text = @"Bark推送";
        barkSwitchLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:barkSwitchLabel];

        _barkSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(panelW-70, y, 51, 31)];
        _barkSwitch.on = barkEnabled;
        [_panelContainer addSubview:_barkSwitch];
        y += 40;

        // Bark 密钥输入框
        UILabel *barkKeyLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, panelW-40, 18)];
        barkKeyLabel.text = @"Bark 密钥";
        barkKeyLabel.font = [UIFont systemFontOfSize:12];
        barkKeyLabel.textColor = [UIColor grayColor];
        [_panelContainer addSubview:barkKeyLabel];
        y += 20;

        _barkKeyField = [[UITextField alloc] initWithFrame:CGRectMake(20, y, panelW-40, 34)];
        _barkKeyField.borderStyle = UITextBorderStyleRoundedRect;
        _barkKeyField.font = [UIFont systemFontOfSize:13];
        _barkKeyField.text = barkKey ?: @"";
        _barkKeyField.placeholder = @"请输入Bark密钥";
        _barkKeyField.delegate = self;
        [_panelContainer addSubview:_barkKeyField];
        y += 42;

        // 倒计时结束关闭App开关
        UILabel *closeAppLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 180, 31)];
        closeAppLabel.text = @"倒计时结束关闭App";
        closeAppLabel.font = [UIFont systemFontOfSize:14];
        [_panelContainer addSubview:closeAppLabel];

        _closeAppSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(panelW-70, y, 51, 31)];
        _closeAppSwitch.on = closeApp;
        [_panelContainer addSubview:_closeAppSwitch];
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
    BOOL barkEnabled = _barkSwitch.on;
    NSString *barkKey = _barkKeyField.text ?: @"";
    NSInteger countdownMin = [_countdownField.text integerValue];
    if (countdownMin <= 0) countdownMin = kDefaultCountdownMin;
    BOOL closeApp = _closeAppSwitch.on;
    CGFloat clickX = [_clickXField.text doubleValue];
    if (clickX <= 0) clickX = kDefaultClickX;
    CGFloat clickY = [_clickYField.text doubleValue];
    if (clickY <= 0) clickY = kDefaultClickY;
    CGFloat delay = [_delayField.text doubleValue];
    if (delay < 0) delay = kDefaultDelay;
    if (self.onSave) self.onSave(text, locked, timeout, cooldown, barkEnabled, barkKey, countdownMin, closeApp, clickX, clickY, delay);
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
@property (nonatomic, strong) UILabel *timerLabel;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSArray<NSDictionary *> *items;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) NSInteger timeout;
@property (nonatomic, assign) NSInteger cooldown;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) NSInteger countdownSeconds;
@property (nonatomic, assign) NSInteger countdownMin;
@property (nonatomic, assign) BOOL closeAppOnEnd;
@property (nonatomic, assign) CGFloat clickX;
@property (nonatomic, assign) CGFloat clickY;
@property (nonatomic, assign) CGFloat delaySeconds;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger elapsedSeconds;
@property (nonatomic, assign) BOOL alertPlayed;
@property (nonatomic, assign) NSTimeInterval lastTapTime;
@property (nonatomic, assign) BOOL delayedActionScheduled;
@end

@implementation FloatView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 8;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowRadius = 4;

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 4, kFloatWidth-8, 14)];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.textColor = [UIColor redColor];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.minimumScaleFactor = 0.5;
        [self addSubview:_titleLabel];

        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 18, kFloatWidth-8, 14)];
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.font = [UIFont systemFontOfSize:12];
        _contentLabel.textColor = [UIColor blueColor];
        _contentLabel.adjustsFontSizeToFitWidth = YES;
        _contentLabel.minimumScaleFactor = 0.5;
        [self addSubview:_contentLabel];

        _timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 34, kFloatWidth-8, 10)];
        _timerLabel.textAlignment = NSTextAlignmentCenter;
        _timerLabel.font = [UIFont systemFontOfSize:7];
        _timerLabel.textColor = [UIColor darkGrayColor];
        _timerLabel.text = @"00:00";
        [self addSubview:_timerLabel];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];

        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        [tap requireGestureRecognizerToFail:doubleTap];

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
    self.paused = [def boolForKey:kPausedKey];
    self.countdownMin = [def integerForKey:kCountdownKey];
    if (self.countdownMin <= 0) self.countdownMin = kDefaultCountdownMin;
    self.closeAppOnEnd = [def boolForKey:kCloseAppKey];
    self.clickX = [def doubleForKey:kClickXKey];
    if (self.clickX <= 0) self.clickX = kDefaultClickX;
    self.clickY = [def doubleForKey:kClickYKey];
    if (self.clickY <= 0) self.clickY = kDefaultClickY;
    self.delaySeconds = [def doubleForKey:kDelayKey];
    if (self.delaySeconds < 0) self.delaySeconds = kDefaultDelay;
    self.delayedActionScheduled = NO;

    for (UIGestureRecognizer *gr in self.gestureRecognizers) {
        if ([gr isKindOfClass:[UIPanGestureRecognizer class]]) {
            gr.enabled = !self.locked;
        }
    }

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

    CGFloat x = [def doubleForKey:kPosXKey];
    CGFloat y = [def doubleForKey:kPosYKey];
    if (x == 0 && y == 0) {
        x = ([UIScreen mainScreen].bounds.size.width - kFloatWidth) / 2;
        y = ([UIScreen mainScreen].bounds.size.height - kFloatHeight) / 2;
    }
    self.frame = CGRectMake(x, y, kFloatWidth, kFloatHeight);
    [self updateLabels];

    if (self.paused) {
        NSTimeInterval startTime = [def doubleForKey:kCountdownStartKey];
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        if (startTime <= 0) {
            startTime = now;
            [def setDouble:startTime forKey:kCountdownStartKey];
        }
        NSInteger elapsed = (NSInteger)(now - startTime);
        NSInteger totalSeconds = self.countdownMin * 60;
        NSInteger remaining = totalSeconds - elapsed;
        self.countdownSeconds = remaining;
        [self updateTimerLabel];
        if (self.countdownSeconds <= 0) {
            if (self.closeAppOnEnd) {
                [self stopTimer];
                exit(0);
            } else {
                if (!self.delayedActionScheduled) {
                    self.delayedActionScheduled = YES;
                    [self performSelector:@selector(performDelayedClick) withObject:nil afterDelay:self.delaySeconds];
                }
            }
        }
        [self startTimer];
        [self updateIdleTimerDisabled];
    } else {
        [self stopTimer];
        self.elapsedSeconds = 0;
        self.alertPlayed = NO;
        [self updateTimerLabel];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void)updateLabels {
    if (self.paused) {
        self.titleLabel.text = @"⏸️";
        self.contentLabel.text = @"暂停";
        return;
    }
    if (self.items.count == 0) {
        self.titleLabel.text = @"";
        self.contentLabel.text = @"";
        return;
    }
    NSDictionary *item = self.items[self.currentIndex];
    self.titleLabel.text = item[@"title"];
    self.contentLabel.text = item[@"content"];
}

- (void)updateTimerLabel {
    NSInteger totalSeconds = self.paused ? self.countdownSeconds : self.elapsedSeconds;
    if (totalSeconds < 0) {
        NSInteger absTotal = labs(totalSeconds);
        NSInteger minutes = absTotal / 60;
        NSInteger seconds = absTotal % 60;
        self.timerLabel.text = [NSString stringWithFormat:@"-%02ld:%02ld", (long)minutes, (long)seconds];
    } else {
        NSInteger minutes = totalSeconds / 60;
        NSInteger seconds = totalSeconds % 60;
        self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    }
}

- (void)updateIdleTimerDisabled {
    [UIApplication sharedApplication].idleTimerDisabled = (self.paused && self.closeAppOnEnd);
}

- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (self.paused) return;
    NSTimeInterval now = CACurrentMediaTime();
    if (self.lastTapTime > 0 && (now - self.lastTapTime) < self.cooldown) {
        return;
    }
    self.lastTapTime = now;
    if (self.items.count > 0) {
        self.currentIndex = (self.currentIndex + 1) % self.items.count;
        [self updateLabels];
        [[NSUserDefaults standardUserDefaults] setInteger:self.currentIndex forKey:kIndexKey];
    }
    [self resetTimer];
    [self sendBarkNotificationIfEnabled];
}

// ===== 统一的点击反馈和发送触摸方法 =====
- (void)showTapMarkerAtPoint:(CGPoint)point {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *targetWindow = nil;
        // 优先使用 keyWindow，如果找不到则使用第一个普通窗口
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if ([NSStringFromClass([w class]) isEqualToString:@"FloatView"]) {
                continue;
            }
            if (w.isKeyWindow) {
                targetWindow = w;
                break;
            }
        }
        if (!targetWindow) {
            targetWindow = [UIApplication sharedApplication].keyWindow;
        }
        if (!targetWindow) return;
        
        // 移除旧标记
        UIView *oldMarker = [targetWindow viewWithTag:9999];
        if (oldMarker) [oldMarker removeFromSuperview];
        
        UIView *marker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        marker.center = point;
        marker.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.9];
        marker.layer.cornerRadius = 15;
        marker.layer.borderWidth = 3;
        marker.layer.borderColor = [UIColor yellowColor].CGColor;
        marker.userInteractionEnabled = NO;
        marker.tag = 9999;
        // 提升层级：使用 UIWindow 来显示，避免被覆盖
        UIWindow *markerWindow = [[UIWindow alloc] initWithWindowScene:[UIApplication sharedApplication].keyWindow.windowScene];
        markerWindow.windowLevel = UIWindowLevelAlert + 2;
        markerWindow.backgroundColor = [UIColor clearColor];
        markerWindow.hidden = NO;
        markerWindow.frame = [UIScreen mainScreen].bounds;
        markerWindow.rootViewController = [UIViewController new];
        [markerWindow.rootViewController.view addSubview:marker];
        // 保存引用以便后续移除（可添加属性，但此处简单用tag标记）
        markerWindow.tag = 9998;
        // 0.5秒后淡出移除
        [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            marker.alpha = 0.0;
        } completion:^(BOOL finished) {
            [marker removeFromSuperview];
            markerWindow.hidden = YES;
            markerWindow = nil;
        }];
        NSLog(@"[FloatInject] 🔴 Marker at (%.0f,%.0f)", point.x, point.y);
    });
}

- (void)sendTapAtPoint:(CGPoint)screenPoint inWindow:(UIWindow *)window withDuration:(NSTimeInterval)duration {
    if (!window) {
        NSLog(@"[FloatInject] ❌ Window is nil");
        return;
    }
    CGPoint windowPoint = [window convertPoint:screenPoint fromWindow:nil];
    NSLog(@"[FloatInject] 📱 Sending touch at screen(%.0f,%.0f) -> window(%.0f,%.0f) duration %.2f", screenPoint.x, screenPoint.y, windowPoint.x, windowPoint.y, duration);
    
    @try {
        UITouch *touch = [[UITouch alloc] initAtPoint:windowPoint inWindow:window];
        if (!touch) { return; }
        [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
        [touch setTapCount:1];
        
        UIEvent *event = [[UIApplication sharedApplication] _touchesEvent];
        [event _clearTouches];
        [event kif_setEventWithTouches:@[touch]];
        [event _addTouch:touch forDelayedDelivery:NO];
        [[UIApplication sharedApplication] sendEvent:event];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
            [event _clearTouches];
            [event kif_setEventWithTouches:@[touch]];
            [event _addTouch:touch forDelayedDelivery:NO];
            [[UIApplication sharedApplication] sendEvent:event];
            NSLog(@"[FloatInject] ✅ Touch ended");
        });
    } @catch (NSException *e) {
        NSLog(@"[FloatInject] ❌ Exception: %@", e);
    }
}

// ===== 立即执行点击（用于双击暂停时） =====
- (void)performClickNow {
    UIWindow *targetWindow = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.windowLevel == 1999.0) {
            targetWindow = w;
            break;
        }
    }
    if (!targetWindow) {
        targetWindow = [UIApplication sharedApplication].keyWindow;
    }
    if (targetWindow) {
        CGPoint clickPoint = CGPointMake(self.clickX, self.clickY);
        [self showTapMarkerAtPoint:clickPoint];
        [self sendTapAtPoint:clickPoint inWindow:targetWindow withDuration:0.2];
    } else {
        NSLog(@"[FloatInject] ⚠️ No window found for tap");
    }
}

// ===== 延迟执行点击（用于倒计时归零后） =====
- (void)performDelayedClick {
    if (!self.paused) {
        self.delayedActionScheduled = NO;
        return;
    }
    self.delayedActionScheduled = NO;
    [self performClickNow];
    // 退出暂停模式
    self.paused = NO;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPausedKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCountdownStartKey];
    [self resetTimer];
    [self updateLabels];
    [self updateIdleTimerDisabled];
    NSLog(@"[FloatInject] 🔄 Exited pause mode after delayed click");
}

// ===== 双击：进入暂停并立即发送点击 =====
- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;
    self.paused = !self.paused;
    [[NSUserDefaults standardUserDefaults] setBool:self.paused forKey:kPausedKey];
    [self updateLabels];

    if (self.paused) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        [[NSUserDefaults standardUserDefaults] setDouble:now forKey:kCountdownStartKey];
        [self resetCountdown];
        // 进入暂停时立即执行一次点击
        [self performClickNow];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCountdownStartKey];
        [self resetTimer];
    }
    [self updateIdleTimerDisabled];
    [self sendBarkNotificationIfEnabled];
}

// 其他方法（handlePan, handleLongPress, resetTimer, resetCountdown, startTimer, stopTimer, timerTick, sendBarkNotificationIfEnabled 等保持不变）
- (void)handlePan:(UIPanGestureRecognizer *)pan {
    // ... 原有实现保持不变 ...
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    // ... 原有实现保持不变，需要更新panel的onSave参数 ...
}

- (void)resetTimer {
    [self stopTimer];
    self.elapsedSeconds = 0;
    self.alertPlayed = NO;
    [self updateTimerLabel];
    [self startTimer];
}

- (void)resetCountdown {
    [self stopTimer];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval startTime = [[NSUserDefaults standardUserDefaults] doubleForKey:kCountdownStartKey];
    NSTimeInterval elapsed = now - startTime;
    NSTimeInterval totalSeconds = self.countdownMin * 60.0;
    self.countdownSeconds = (NSInteger)(totalSeconds - elapsed);
    [self updateTimerLabel];
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
    if (self.paused) {
        self.countdownSeconds--;
        [self updateTimerLabel];
        // 当倒计时变为 -1 或更小，且尚未调度延迟操作，且 closeAppOnEnd == YES 时关闭（但用户要求不管开关都执行点击）
        // 按照新需求：不管 closeAppOnEnd，只要 countdownSeconds <= -1 就触发延迟点击
        if (self.countdownSeconds <= -1 && !self.delayedActionScheduled) {
            // 如果 closeAppOnEnd 为 YES，则关闭 APP（原有逻辑）
            if (self.closeAppOnEnd) {
                [self stopTimer];
                exit(0);
            } else {
                // 否则调度延迟点击
                self.delayedActionScheduled = YES;
                [self performSelector:@selector(performDelayedClick) withObject:nil afterDelay:self.delaySeconds];
            }
        }
        // 如果 closeAppOnEnd == YES 且倒计时恰好为0，则立即关闭
        if (self.countdownSeconds == 0 && self.closeAppOnEnd) {
            [self stopTimer];
            exit(0);
        }
    } else {
        self.elapsedSeconds++;
        [self updateTimerLabel];
        if (self.elapsedSeconds >= self.timeout) {
            if (!self.alertPlayed) {
                self.alertPlayed = YES;
                AudioServicesPlaySystemSound(1020);
                [self stopTimer];
            }
        }
    }
}

- (void)sendBarkNotificationIfEnabled {
    // ... 原有实现保持不变 ...
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