//
//  DMPasscode.h
//  DMPasscode
//
//  Created by Dylan Marriott on 20/09/14.
//  Copyright (c) 2014 Dylan Marriott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DMPasscodeConfig.h"

typedef void (^PasscodeCompletionBlock)(BOOL success, NSError *error);

typedef NS_ENUM(NSInteger, DMUnlockErrorCodes)
{
    DMErrorUnlocking = -1,
    DMMaxAttempts    = -2
};


/**
 *  The passcode screen has to be manually opened. You decide when it should be presented.
 *  The chosen code is stored inside the keychain.
 *  First let the user set a passcode by calling the setupPasscodeInViewController:completion: method.
 *  If you want to authenticate the user, simple call showPasscodeInViewController:completion.
 */
@interface DMPasscode : NSObject

/**
 *  Setup a new passcode.
 *
 *  @param viewController The view controller in which the passcode screen will be presented
 *  @param completion     The completion block with a BOOL to inidcate if authentication was successful (and NSError if not)
 */
+ (void)setupPasscodeInViewController:(UIViewController *)viewController completion:(PasscodeCompletionBlock)completion;

/**
 *  Authenticate the user.
 *
 *  @param viewController The view controller in which the passcode screen will be presented
 *  @param completion     The completion block with a BOOL to inidcate if the authentication was successful (and NSError if not)
 */
+ (void)showPasscodeInViewController:(UIViewController *)viewController                          
                          completion:(PasscodeCompletionBlock)completion;
+ (void)showPasscodeInViewController:(UIViewController *)viewController
                          strictAuth:(BOOL)strictAuth
                          completion:(PasscodeCompletionBlock)completion;
/**
 *  Authenticate the user.
 *
 *  @param completion     The completion block with a BOOL to inidcate if the authentication was successful (and NSError if not)
    @return UIViewController pass code view controller for display 
 */
+ (UIViewController *)strictPasscodeVCCompletion:(PasscodeCompletionBlock)completion;
/**
 *  Remove the passcode from the keychain.
 */
+ (void)removePasscode;

/**
 *  Check if a passcode is already set.
 *
 *  @return BOOL indicating if a passcode is set
 */
+ (BOOL)isPasscodeSet;

/**
 *  Set a configuration.
 *
 *  @param config configuration which should be uses.
 */
+ (void)setConfig:(DMPasscodeConfig *)config;

/**
 *  Check if touch ID is enable
 *
 *  @return BOOL indicating if touch id is enable
 */

+ (BOOL) canUseBioIdInsteadOfPin;

+ (void) setCanUseBioIdInsteadOfPin:(BOOL)can;

+ (BOOL) isDeviceSupportBioId;


//RESET KEYCHAIN
+ (void)resetKeyChain;

// added by bunny

/**
 *  Setup a new passcode.
 *
 *  @param navController The view controller in which the passcode screen will be pushed in
 *  @param completion     The completion block with a BOOL to inidcate if authentication was successful (and NSError if not)
 */
+ (void)setupPasscodeInSheetNavViewController:(UINavigationController *)navController
                                   completion:(PasscodeCompletionBlock)completion;

/**
 *  This function is used for user to auth first then reset new passcode
 *
 *  @param navController The view controller in which the passcode screen will be pushed
 *  @param completion     The completion block with a BOOL to inidcate if the authentication was successful (and NSError if not)
 */
+ (void)showResetPasscodeInSheetNavViewController:(UINavigationController *)navController
                                       completion:(PasscodeCompletionBlock)completion;



@end
