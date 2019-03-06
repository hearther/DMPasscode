//
//  DMPasscode.m
//  DMPasscode
//
//  Created by Dylan Marriott on 20/09/14.
//  Copyright (c) 2014 Dylan Marriott. All rights reserved.
//

#import "DMPasscode.h"
#import "DMPasscodeInternalNavigationController.h"
#import "DMPasscodeInternalViewController.h"
#import "DMKeychain.h"

#ifdef __IPHONE_8_0
#import <LocalAuthentication/LocalAuthentication.h>
#endif

#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSInteger, DMPassCodeModes)
{
    DMPassCodeSetUp          = 0,
    DMPassCodeInput          = 1,
    DMPassCodeResetInput     = 2,
    DMPasscodeStrictAuth    = 3,
    DMPasscodeStrictAuthC    = 4,
    
};
//_mode
// DMPassCodeSetUp = setup
// DMPassCodeInput = input,
// DMPasscodeStrictAuth = strict auth, user can't be cancel this
// DMPasscodeStrictAuthC = strict auth, user can't be cancel this, and return DMPasscodeInternalViewController for other to display

@implementation UINavigationController (CompletionHandler)

- (void)completionhandler_pushViewController:(UIViewController *)viewController
                                    animated:(BOOL)animated
                                  completion:(void (^)(void))completion
{
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    [self pushViewController:viewController animated:animated];
    [CATransaction commit];
}

@end

//#undef NSLocalizedString
//#define NSLocalizedString(key, comment) \
[bundle localizedStringForKey:(key) value:@"" table:@"DMPasscodeLocalisation"]

static DMPasscode* instance;
static const NSString* KEYCHAIN_NAME = @"passcode";
static const NSString* KEYCHAIN_NAME_ENABLE_BIO_ID = @"enableBioId";
static const NSString* KEYCHAIN_NAME_MAX_ATTEMPTS_TIME = @"maxAttemptTime";
static NSBundle* bundle;
NSString * const DMUnlockErrorDomain = @"com.dmpasscode.error.unlock";

@interface DMPasscode () <DMPasscodeInternalViewControllerDelegate>
@end

@implementation DMPasscode {
    PasscodeCompletionBlock _completion;
    DMPasscodeInternalViewController* _passcodeViewController;
    DMPassCodeModes _mode;
    BOOL _pushInSheetNav;
    int _count;
    NSString* _prevCode;
    DMPasscodeConfig* _config;
}

+ (void)initialize {
    [super initialize];
    instance = [[DMPasscode alloc] init];
    bundle = [DMPasscode bundleWithName:@"DMPasscode.bundle"];
}

- (instancetype)init {
    if (self = [super init]) {
        _config = [[DMPasscodeConfig alloc] init];
    }
    return self;
}




+ (NSBundle*)bundleWithName:(NSString*)name {
    NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
    NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:frameworkBundlePath]){
        return [NSBundle bundleWithPath:frameworkBundlePath];
    }
    return nil;
}

#pragma mark - Public
+ (void)setupPasscodeInViewController:(UIViewController *)viewController completion:(PasscodeCompletionBlock)completion {
    [instance setupPasscodeInViewController:viewController completion:completion];
}

+ (void)showPasscodeInViewController:(UIViewController *)viewController
                          strictAuth:(BOOL)strictAuth
                          completion:(PasscodeCompletionBlock)completion {
    [instance showPasscodeInViewController:viewController
                                strictAuth:strictAuth
                                completion:completion];
}

+ (void)showPasscodeInViewController:(UIViewController *)viewController
                          completion:(PasscodeCompletionBlock)completion
{
    [self showPasscodeInViewController:viewController
                            strictAuth:NO
                            completion:completion];
}

+ (UIViewController *)strictPasscodeVCCompletion:(PasscodeCompletionBlock)completion
{
    return [instance strictPasscodeViewControllerCompletion:completion];
}

+ (void)removePasscode {
    [instance removePasscode];
}

+ (BOOL)isPasscodeSet {
    return [instance isPasscodeSet];
}

+ (void)setConfig:(DMPasscodeConfig *)config {
    [instance setConfig:config];
}

+ (BOOL) canUseBioIdInsteadOfPin{
    return [instance canUseBioIdInsteadOfPin];
}

+ (void) setCanUseBioIdInsteadOfPin:(BOOL)enable{
    [instance setCanUseBioIdInsteadOfPin:enable];
}

+ (double) maxAttemptsTime{
    return [instance maxAttemptsTime];
}

+ (BOOL) isDeviceSupportBioId{
    LAContext* context = [[LAContext alloc] init];
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                             error:nil])
    {
        return YES;
    }
    else {
        return NO;
    }
}

+ (void)resetKeyChain{
    [[DMKeychain defaultKeychain] removeObjectForKey:KEYCHAIN_NAME];
    [[DMKeychain defaultKeychain] removeObjectForKey:KEYCHAIN_NAME_ENABLE_BIO_ID];
    [[DMKeychain defaultKeychain] removeObjectForKey:KEYCHAIN_NAME_MAX_ATTEMPTS_TIME];
}

// added by bunny
+ (void)setupPasscodeInSheetNavViewController:(UINavigationController *)navController
                              completion:(PasscodeCompletionBlock)completion
{
    [instance setupPasscodeInSheetNavViewController:navController completion:completion];
}

+ (void)showResetPasscodeInSheetNavViewController:(UINavigationController *)navController
                                 completion:(PasscodeCompletionBlock)completion
{
    [instance showResetPasscodeInSheetNavViewController:navController completion:completion];
}

#pragma mark - Instance methods
- (void)setupPasscodeInViewController:(UIViewController *)viewController completion:(PasscodeCompletionBlock)completion {
    _completion = completion;
    [self openPasscodeWithMode:0 viewController:viewController];
}


- (UIViewController *)strictPasscodeViewControllerCompletion:(PasscodeCompletionBlock)completion
{
    NSAssert([self isPasscodeSet], @"No passcode set");
    _completion = completion;
    
    // show pass code view
    return [self strictPasscodeVC];
}

- (void)showPasscodeInViewController:(UIViewController *)viewController
                          strictAuth:(BOOL)strictAuth
                          completion:(PasscodeCompletionBlock)completion
{
    NSAssert([self isPasscodeSet], @"No passcode set");
    _completion = completion;
 
    double maxAttemptsTime = [self maxAttemptsTime];
    
    if (maxAttemptsTime >0)
    {
        NSTimeInterval curTimestamp = [[NSDate date] timeIntervalSince1970];
        //last is max attemp need to wait unitl ....
        if (curTimestamp < maxAttemptsTime+_config.maxAttemptsFailWaitSeconds){
            NSError *error = [NSError errorWithDomain:@"DMPasscode"
                                                 code:DMMaxAttempts
                                             userInfo:nil];
            _completion(NO, error);
            return;
        }
    }
    // show pass code view
    [self openPasscodeWithMode:strictAuth?2:1 viewController:viewController];
}

- (void)removePasscode {
    [[DMKeychain defaultKeychain] removeObjectForKey:KEYCHAIN_NAME];
}

- (BOOL)isPasscodeSet {
    BOOL ret = [[DMKeychain defaultKeychain] objectForKey:KEYCHAIN_NAME] != nil;
    return ret;
}

- (void) setCanUseBioIdInsteadOfPin:(BOOL)can{
    [[DMKeychain defaultKeychain] setObject:[NSNumber numberWithBool:can]
                                     forKey:KEYCHAIN_NAME_ENABLE_BIO_ID];
}


- (BOOL) canUseBioIdInsteadOfPin{
    NSNumber *enable = [[DMKeychain defaultKeychain] objectForKey:KEYCHAIN_NAME_ENABLE_BIO_ID];
    return [enable boolValue];
}


- (double) maxAttemptsTime{
    NSNumber *date = [[DMKeychain defaultKeychain] objectForKey:KEYCHAIN_NAME_MAX_ATTEMPTS_TIME];
    double ret = [date doubleValue];
    return ret;
}


- (void)setConfig:(DMPasscodeConfig *)config {
    _config = config;
}

- (void)setupPasscodeInSheetNavViewController:(UINavigationController *)navController
                              completion:(PasscodeCompletionBlock)completion
{
    if (![navController isKindOfClass:[UINavigationController class]])
    {
        if (completion){
            completion(NO, nil);
        }
        return;
    }
    
    _completion = completion;
    [self openPasscodeWithMode:0 sheetNavController:navController];
}
- (void) showPasscodeInSheetNavViewController:(UINavigationController *)navController
                                   strictAuth:(BOOL) strictAuth
                                resetPassWord:(BOOL) resetPassWord
                                   completion:(PasscodeCompletionBlock)completion
{
    if (![navController isKindOfClass:[UINavigationController class]])
    {
        if (completion){
            completion(NO, nil);
        }
        return;
    }
    
    NSAssert([self isPasscodeSet], @"No passcode set");
    _completion = completion;
    
    double maxAttemptsTime = [self maxAttemptsTime];
    
    if (maxAttemptsTime >0)
    {
        NSTimeInterval curTimestamp = [[NSDate date] timeIntervalSince1970];
        //last is max attemp need to wait unitl ....
        if (curTimestamp < maxAttemptsTime+_config.maxAttemptsFailWaitSeconds){
            NSError *error = [NSError errorWithDomain:@"DMPasscode"
                                                 code:DMMaxAttempts
                                             userInfo:nil];
            _completion(NO, error);
            return;
        }
    }
    // show pass code view
    DMPassCodeModes mode = DMPassCodeSetUp;
    if (resetPassWord){
        mode = DMPassCodeResetInput;
    }
    else if (strictAuth){
        mode = DMPasscodeStrictAuth;
    }
    else{
        mode = DMPassCodeInput;
    }
    
    [self openPasscodeWithMode:mode sheetNavController:navController];
}

- (void)showResetPasscodeInSheetNavViewController:(UINavigationController *)navController
                                      completion:(PasscodeCompletionBlock)completion
{
    
    //check old first
    [self showPasscodeInSheetNavViewController:navController
                                    strictAuth:NO
                                 resetPassWord:YES
                                    completion:completion];
    
}

#pragma mark - Private
- (UIViewController *) strictPasscodeVC
{
    _mode = DMPasscodeStrictAuthC;
    _count = 0;
    _pushInSheetNav = NO;
    _passcodeViewController =
    [[DMPasscodeInternalViewController alloc] initWithDelegate:self
                                                        config:_config
                                                  needCloseBtn:NO];
    DMPasscodeInternalNavigationController* nc = [[DMPasscodeInternalNavigationController alloc] initWithRootViewController:_passcodeViewController];

    [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_enter_to_unlock", nil)];
    nc.navigationItem.leftBarButtonItem = NULL;
    
    return nc;
}

- (void)openPasscodeWithMode:(DMPassCodeModes) mode
              viewController:(UIViewController *) viewController
{
    _mode = mode;
    _count = 0;
    _pushInSheetNav = NO;
    _passcodeViewController =
    [[DMPasscodeInternalViewController alloc] initWithDelegate:self
                                                        config:_config
                                                  needCloseBtn:mode==2?NO:YES];
    DMPasscodeInternalNavigationController* nc = [[DMPasscodeInternalNavigationController alloc] initWithRootViewController:_passcodeViewController];
    [viewController presentViewController:nc
                                 animated:YES
                               completion:^
    {
        LAContext* context = [[LAContext alloc] init];
        if ([self canUseBioIdInsteadOfPin] &&
            [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil])
        {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                    localizedReason:NSLocalizedString(@"dmpasscode_touchid_reason", nil) reply:^(BOOL success, NSError* error)
            {
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self closeAndNotify:YES withError:nil];
                    });
                }
            }];
        }
    }];
    if (_mode == DMPassCodeSetUp) {
        [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_enter_new_code", nil)];
        
        NSString *htmlString = NSLocalizedString(@"dmpasscode_enter_new_code_detail", nil);                
        [_passcodeViewController setDetail:htmlString
                                 tapTarget:self
                                 tapAction:@selector(tapDetail:)];
    } else if (_mode == DMPassCodeInput || _mode == DMPassCodeResetInput) {
        [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_enter_to_unlock", nil)];
    }
    else if (_mode == DMPasscodeStrictAuth) {
        [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_enter_to_unlock", nil)];
        nc.navigationItem.leftBarButtonItem = NULL;
    }
}

- (void)closeAndNotify:(BOOL)success withError:(NSError *)error
{
    
    if ([_passcodeViewController.navigationController isKindOfClass:[DMPasscodeInternalNavigationController class]] &&
        _passcodeViewController.presentingViewController != NULL)
    {
        [_passcodeViewController dismissViewControllerAnimated:YES completion:^() {
            _completion(success, error);
        }];
    }
    else if ([_passcodeViewController.navigationController isKindOfClass:[UINavigationController class]] &&
             _pushInSheetNav == YES)
    {
        [_passcodeViewController.navigationController popViewControllerAnimated:YES];
        _completion(success, error);
        _pushInSheetNav = NO;
    }
    else {
       _completion(success, error);
    }
}

- (void)openPasscodeWithMode:(DMPassCodeModes)mode
          sheetNavController:(UINavigationController *)navController
{
    _mode = mode;
    _count = 0;
    _pushInSheetNav = YES;
    _passcodeViewController =
    [[DMPasscodeInternalViewController alloc] initWithDelegate:self
                                                        config:_config
                                                  needCloseBtn:NO
                                                pushInSheetNav:YES];
    
    [navController completionhandler_pushViewController:_passcodeViewController
                                               animated:YES
                                             completion:^
    {
        LAContext* context = [[LAContext alloc] init];
        if ([self canUseBioIdInsteadOfPin] &&
            [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil])
        {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                    localizedReason:NSLocalizedString(@"dmpasscode_touchid_reason", nil) reply:^(BOOL success, NSError* error)
             {
                 if (success) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self closeAndNotify:YES withError:nil];
                     });
                 }
             }];
        }
    }];
    
    
    if (_mode == DMPassCodeSetUp) {
        [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_enter_new_code", nil)];
        
        NSString *htmlString = NSLocalizedString(@"dmpasscode_enter_new_code_detail", nil);
        [_passcodeViewController setDetail:htmlString
                                 tapTarget:self
                                 tapAction:@selector(tapDetail:)];
    } else if (_mode == DMPassCodeInput || _mode == DMPassCodeResetInput) {
        [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_enter_to_unlock", nil)];
    }
    else if (_mode == DMPasscodeStrictAuth) {
        [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_enter_to_unlock", nil)];
        navController.navigationItem.leftBarButtonItem = NULL;
    }
}

#pragma mark - DMPasscodeInternalViewControllerDelegate
- (void)viewDidAppear
{
    NSLog(@"%s _mode %d",__func__, _mode);
    if (_mode == DMPasscodeStrictAuthC)
    {
        
        LAContext* context = [[LAContext alloc] init];
        NSError *error;
        if ([self canUseBioIdInsteadOfPin] &&
            [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                                 error:&error])
        {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                    localizedReason:NSLocalizedString(@"dmpasscode_touchid_reason", nil)
                              reply:^(BOOL success, NSError* error)
             {
                 if (success) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                      [self closeAndNotify:YES withError:nil];
                  });
                     NSLog(@"%s evaluatePolicy error %@",__func__, error);
              }
          }];
        }
        NSLog(@"%s canEvaluatePolicy error %@",__func__, error);
    }
}
- (void)enteredCode:(NSString *)code {
    if (_mode == DMPassCodeSetUp) {
        if (_count == 0) {
            _prevCode = code;
            [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_repeat", nil)];
            [_passcodeViewController setErrorMessage:@""];
            [_passcodeViewController reset];
        } else if (_count == 1) {
            if ([code isEqualToString:_prevCode]) {
                [[DMKeychain defaultKeychain] setObject:code forKey:KEYCHAIN_NAME];
                [self closeAndNotify:YES withError:nil];
            } else {
                [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_enter_new_code", nil)];
                [_passcodeViewController setErrorMessage:NSLocalizedString(@"dmpasscode_not_match", nil)];
                [_passcodeViewController reset];
                _count = 0;
                return;
            }
        }
    } else if (_mode == DMPassCodeInput ||
               _mode == DMPassCodeResetInput ||
               _mode == DMPasscodeStrictAuth ||
               _mode == DMPasscodeStrictAuthC)
    {
        if ([code isEqualToString:[[DMKeychain defaultKeychain] objectForKey:KEYCHAIN_NAME]])
        {
            if (_mode == DMPassCodeResetInput)
            {
                //ask user to input new code
                _mode = DMPassCodeSetUp;
                [_passcodeViewController setInstructions:NSLocalizedString(@"dmpasscode_enter_new_code", nil)];
                [_passcodeViewController reset];
                _count = 0;
                return;
            }
            else {
                [self closeAndNotify:YES withError:nil];
            }
        } else {
            
            if (_config.maxAttempts > 0){
            [_passcodeViewController setErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"dmpasscode_n_left", nil), (_config.maxAttempts-1) - _count]];
            
            [_passcodeViewController reset];
            if (_count >= (_config.maxAttempts-1)) { // max attempts
                NSError *errorMatchingPins = [NSError errorWithDomain:DMUnlockErrorDomain code:DMErrorUnlocking userInfo:nil];
                [self closeAndNotify:NO withError:errorMatchingPins];
                NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
                [[DMKeychain defaultKeychain] setObject:[NSNumber numberWithDouble:timestamp]
                                                 forKey:KEYCHAIN_NAME_MAX_ATTEMPTS_TIME];
            }
        }
            else {
                [_passcodeViewController reset];
            }
        }
    }
    _count++;
}

- (void)canceled {
    _completion(NO, nil);
}

- (void)tapDetail:(id)sender{
    
    
    NSString *url = _config.detailOpenURL;
    if (url){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
    
}
@end
