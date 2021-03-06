//
//  DMPasscodeInternalViewController.m
//  Pods
//
//  Created by Dylan Marriott on 20/09/14.
//
//

#import "DMPasscodeInternalViewController.h"
#import "DMPasscodeInternalField.h"
#import "DMPasscodeConfig.h"

@interface DMPasscodeInternalViewController () <UITextFieldDelegate>
@end

@implementation DMPasscodeInternalViewController {
    __weak id<DMPasscodeInternalViewControllerDelegate> _delegate;
    NSMutableArray* _textFields;
    UITextField* _input;
    UILabel* _instructions;
    UILabel* _error;
    DMPasscodeConfig* _config;
    UIButton* _detail;
    BOOL _needCloseBtn, _pushInSheetNav;
}

- (id)initWithDelegate:(id<DMPasscodeInternalViewControllerDelegate>)delegate
                config:(DMPasscodeConfig *)config
          needCloseBtn:(BOOL)needCloseBtn
{
    if (self = [super init]) {
        _delegate = delegate;
        _config = config;
        _instructions = [[UILabel alloc] init];
        _error = [[UILabel alloc] init];
        _textFields = [[NSMutableArray alloc] init];
        _detail = [[UIButton alloc] init];
        _needCloseBtn = needCloseBtn;
    }
    return self;
}

- (id)initWithDelegate:(id<DMPasscodeInternalViewControllerDelegate>)delegate
                config:(DMPasscodeConfig *)config
          needCloseBtn:(BOOL)needCloseBtn
        pushInSheetNav:(BOOL)pushInSheetNav
{
    if (self = [self initWithDelegate:delegate
                           config:config
                     needCloseBtn:needCloseBtn])
    {
        _pushInSheetNav = pushInSheetNav;
    }
    return self;    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = _config.backgroundColor;
    self.navigationController.navigationBar.barTintColor = _config.navigationBarBackgroundColor;
    if (_needCloseBtn && !_pushInSheetNav)
    {
        UIBarButtonItem* closeItem = nil;
        if (_config.closeImgName){
            closeItem = [self barButtonItemForImageName:_config.closeImgName
                                                 target:self
                                                 action:@selector(close:)];
        }
        else {
            closeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(close:)];
        }
        
        closeItem.tintColor = _config.navigationBarForegroundColor;
        self.navigationItem.leftBarButtonItem = closeItem;
    }
    
    
    
    self.navigationController.navigationBar.barStyle = (UIBarStyle)_config.statusBarStyle;
    self.navigationController.navigationBar.titleTextAttributes = @{NSFontAttributeName :_config.navigationBarFont,
                                                                    NSForegroundColorAttributeName: _config.navigationBarTitleColor};
    self.title = _config.navigationBarTitle;

    if (_config.titleView != nil) {
      self.navigationItem.titleView = _config.titleView;
    }

    _instructions.frame = CGRectMake(0, 85, self.view.frame.size.width, 30);
    _instructions.font = _config.instructionsFont;
    _instructions.textColor = _config.descriptionColor;
    _instructions.textAlignment = NSTextAlignmentCenter;
    _instructions.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_instructions];

    _error.frame = CGRectMake(0, 190, 0, 0); // size set when text is set
    _error.font = _config.errorFont;
    _error.textColor = _config.errorForegroundColor;
    _error.backgroundColor = _config.errorBackgroundColor;
    _error.textAlignment = NSTextAlignmentCenter;
    _error.layer.cornerRadius = 4;
    _error.clipsToBounds = YES;
    _error.alpha = 0;
    _error.numberOfLines = 0;
    _error.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:_error];

    CGFloat y_padding = 140;
    CGFloat itemWidth = 24;
    CGFloat space = 20;
    
    int fieldNum = _config.passFieldNum;
    CGFloat totalWidth = (itemWidth * fieldNum) + (space * (fieldNum-1));
    CGFloat x_padding = (self.view.bounds.size.width - totalWidth) / 2;

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(x_padding, y_padding, totalWidth, itemWidth)];
    container.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    for (int i = 0; i < fieldNum; i++) {
        DMPasscodeInternalField* field = [[DMPasscodeInternalField alloc] initWithFrame:CGRectMake(((itemWidth + space) * i), 0, itemWidth, itemWidth) config:_config];
        UITapGestureRecognizer* singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [field addGestureRecognizer:singleFingerTap];
        [container addSubview:field];
        [_textFields addObject:field];
    }
    [self.view addSubview:container];


    _input = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [_input setDelegate:self];
    [_input addTarget:self action:@selector(editingChanged:) forControlEvents:UIControlEventEditingChanged];
    _input.keyboardType = _config.defaultKeyboardType;
    _input.keyboardAppearance = _config.inputKeyboardAppearance;
    // _input.secureTextEntry = YES;
    _input.autocorrectionType = UITextAutocorrectionTypeNo;
    _input.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:_input];
    [_input becomeFirstResponder];
    
    
    _detail.frame = CGRectMake(0, 190, 0, 0);
    [_detail setBackgroundColor:[UIColor clearColor]];
    _detail.font = _config.instructionsFont;
    _detail.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    _detail.titleLabel.textColor = _config.descriptionColor;
    _detail.titleLabel.textAlignment = NSTextAlignmentCenter;
    _detail.titleLabel.numberOfLines = 0;
    _detail.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:_detail];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (_pushInSheetNav && [[self.navigationController viewControllers] count] >0)
    {
        UIBarButtonItem* backItem = nil;
        if (_config.backImgName){
            backItem = [self barButtonItemForImageName:_config.backImgName
                                                target:self
                                                action:@selector(back:)];
        }
        else {
            backItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(back:)];
        }
        
        backItem.tintColor = _config.navigationBarForegroundColor;
        self.navigationItem.leftBarButtonItem = backItem;
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //wait for ui to finish
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [_delegate viewDidAppear];
    });
}

-(void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    if([_input isFirstResponder]){
        [_input resignFirstResponder];
    }
    [_input becomeFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    return newLength <= _config.passFieldNum|| returnKey;
}

- (void)editingChanged:(UITextField *)sender {
    for (int i = 0; i < sender.text.length; i++) {
        DMPasscodeInternalField* field = [_textFields objectAtIndex:i];
        NSRange range;
        range.length = 1;
        range.location = i;
        field.text = [sender.text substringWithRange:range];
    }
    for (int i = (int)sender.text.length; i < _config.passFieldNum; i++) {
        DMPasscodeInternalField* field = [_textFields objectAtIndex:i];
        field.text = @"";
    }

    NSString* code = sender.text;
    if (code.length == _config.passFieldNum)
    {
        //delay 0.5 seconds for UI animate
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [_delegate enteredCode:code];
        });
    }
}

- (void)close:(id)sender {
    [_input resignFirstResponder];
    if (_pushInSheetNav){
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [_delegate canceled];
}

- (void)back:(id)sender {
    [_input resignFirstResponder];
    [_delegate canceled];
}

- (void)reset {
    for (DMPasscodeInternalField* field in _textFields) {
        field.text = @"";
    }
    _input.text = @"";
}

- (void)setErrorMessage:(NSString *)errorMessage {
    if (errorMessage.length == 0){
        [_detail setHidden:NO];
    }
    else {
        [_detail setHidden:YES];
    }
    _error.text = errorMessage;
    _error.alpha = errorMessage.length > 0 ? 1.0f : 0.0f;

    CGSize size = [_error.text sizeWithAttributes:@{NSFontAttributeName: _error.font}];
    size.width += 28;
    size.height += 28;
    _error.frame = CGRectMake(self.view.frame.size.width / 2 - size.width / 2, _error.frame.origin.y, size.width, size.height);
}

- (void)setInstructions:(NSString *)instructions {
    _instructions.text = instructions;
}
- (void)setDetail:(NSString *)detail
        tapTarget:(id) target
        tapAction:(SEL)action
{
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    
    NSMutableAttributedString* htmlStr =
    [[NSMutableAttributedString alloc] initWithData:[detail dataUsingEncoding:NSUTF8StringEncoding]
                                            options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,                                                                                       NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]}
                                 documentAttributes:nil
                                              error:nil];
    [htmlStr addAttributes:@{NSParagraphStyleAttributeName: style}
                     range:NSMakeRange(0, htmlStr.length)];
    
    [_detail setAttributedTitle:htmlStr forState:UIControlStateNormal];
    
    CGSize size = [_detail.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: _detail.titleLabel.font}];
    size.width = MIN(self.view.frame.size.width-28, size.width+28);
    size.height += 28;
    _detail.frame = CGRectMake(self.view.frame.size.width / 2 - size.width / 2, _detail.frame.origin.y, size.width, size.height);

    if (target != NULL && action != NULL){
        [_detail addTarget:target
                    action:action
          forControlEvents:UIControlEventTouchUpInside];
    }
}

- (UIBarButtonItem *) barButtonItemForImageName:(NSString *)imageName
                                         target:(id)target
                                         action:(SEL)action
{
    UIButton            *button;
    UIBarButtonItem        *item;
    
    button = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
    UIImage *img = [UIImage imageNamed:imageName];
    [button setImage:img
            forState:UIControlStateNormal];
    
    button.autoresizingMask =
    (UIViewAutoresizingFlexibleWidth |
     UIViewAutoresizingFlexibleHeight);
    [[button imageView] setContentMode:UIViewContentModeScaleAspectFit];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    item = [[UIBarButtonItem alloc] initWithCustomView:button];
    return item;
}

@end
