/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 */

#import <Cordova/CDVViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>

static char CDVOrientationSupportedOrientationsKey;

static NSArray *CDVOrientationGetSupportedOrientations(id viewController, SEL selector)
{
    return objc_getAssociatedObject(viewController, &CDVOrientationSupportedOrientationsKey);
}

static void CDVOrientationSetSupportedOrientations(id viewController, SEL selector, NSArray *orientations)
{
    objc_setAssociatedObject(viewController, &CDVOrientationSupportedOrientationsKey,
        [orientations copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static UIInterfaceOrientationMask CDVOrientationCallSuperSupportedInterfaceOrientations(id viewController, SEL selector)
{
    struct objc_super superInfo = {
        .receiver = viewController,
        .super_class = class_getSuperclass([CDVViewController class])
    };

    return ((UIInterfaceOrientationMask (*)(struct objc_super *, SEL))objc_msgSendSuper)(&superInfo, selector);
}

static UIInterfaceOrientationMask CDVOrientationGetSupportedInterfaceOrientations(id viewController, SEL selector)
{
    NSArray *orientations = CDVOrientationGetSupportedOrientations(viewController, @selector(supportedOrientations));
    if (orientations.count == 0) {
        return CDVOrientationCallSuperSupportedInterfaceOrientations(viewController, selector);
    }

    UIInterfaceOrientationMask orientationMask = 0;
    for (NSNumber *orientationValue in orientations) {
        switch ((UIInterfaceOrientation)orientationValue.integerValue) {
            case UIInterfaceOrientationPortrait:
                orientationMask |= UIInterfaceOrientationMaskPortrait;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                orientationMask |= UIInterfaceOrientationMaskPortraitUpsideDown;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                orientationMask |= UIInterfaceOrientationMaskLandscapeLeft;
                break;
            case UIInterfaceOrientationLandscapeRight:
                orientationMask |= UIInterfaceOrientationMaskLandscapeRight;
                break;
            default:
                break;
        }
    }

    if (orientationMask == 0) {
        return CDVOrientationCallSuperSupportedInterfaceOrientations(viewController, selector);
    }

    return orientationMask;
}

@interface CDVViewController (CDVOrientation)
@end

@implementation CDVViewController (CDVOrientation)

+ (void)load
{
    Class viewControllerClass = [CDVViewController class];
    Method supportedInterfaceOrientationsMethod =
        class_getInstanceMethod([UIViewController class], @selector(supportedInterfaceOrientations));

    class_addMethod(viewControllerClass,
        NSSelectorFromString(@"supportedOrientations"),
        (IMP)CDVOrientationGetSupportedOrientations,
        "@@:");
    class_addMethod(viewControllerClass,
        NSSelectorFromString(@"setSupportedOrientations:"),
        (IMP)CDVOrientationSetSupportedOrientations,
        "v@:@");
    if (supportedInterfaceOrientationsMethod != NULL) {
        class_addMethod(viewControllerClass,
            @selector(supportedInterfaceOrientations),
            (IMP)CDVOrientationGetSupportedInterfaceOrientations,
            method_getTypeEncoding(supportedInterfaceOrientationsMethod));
    }
}

@end
