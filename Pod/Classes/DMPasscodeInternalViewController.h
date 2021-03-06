//
//  DMPasscodeInternalViewController.h
//  Pods
//
//  Created by Dylan Marriott on 20/09/14.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DMPasscodeInternalViewControllerDelegate <NSObject>

- (void)enteredCode:(NSString *)code;
- (void)canceled;
@optional
- (void) viewDidAppear;
@end

@class DMPasscodeConfig;

@interface DMPasscodeInternalViewController : UIViewController

- (id)initWithDelegate:(id<DMPasscodeInternalViewControllerDelegate>)delegate
                config:(DMPasscodeConfig *)config
          needCloseBtn:(BOOL)needCloseBtn;
- (void)reset;
- (void)setErrorMessage:(NSString *)errorMessage;
- (void)setInstructions:(NSString *)instructions;
- (void)setDetail:(NSString *)detail
        tapTarget:(id) target
        tapAction:(SEL)action;


- (id)initWithDelegate:(id<DMPasscodeInternalViewControllerDelegate>)delegate
                config:(DMPasscodeConfig *)config
          needCloseBtn:(BOOL)needCloseBtn
        pushInSheetNav:(BOOL)pushInSheetNav;
@end
