//
// Copyright 2018 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GREYElementInteractionErrorHandler.h"

#import "GREYAssertionDefinesPrivate.h"
#import "GREYError+Private.h"
#import "GREYErrorConstants.h"
#import "GREYFailureHandler.h"
#import "GREYFrameworkException.h"

@implementation GREYElementInteractionErrorHandler

/**
 *  Handles and sets the error based on the interaction related placeholder error value.
 *
 *  @param interactionError Error returned from the interaction.
 *  @param errorOrNil       Error passed in by the user.
 *
 *  @return @c NO if any error is returned from the interaction, @c YES otherwise.
 */
+ (BOOL)handleInteractionError:(__strong GREYError *)interactionError
                      outError:(__autoreleasing NSError **)errorOrNil {
  if (interactionError) {
    if (errorOrNil) {
      *errorOrNil = interactionError;
    } else {
      NSString *reason;
      NSString *matcherDetails;
      NSString *localizedFailureReason =
          interactionError.userInfo[NSLocalizedFailureReasonErrorKey];
      if (localizedFailureReason) {
        reason = localizedFailureReason;
      } else {
        NSMutableString *mutableReason = [interactionError.localizedDescription mutableCopy];
        NSString *mismatchInfo = interactionError.errorInfo[@"Mismatch"];
        if (mismatchInfo) {
          [mutableReason appendFormat:@"\nMismatch: %@", mismatchInfo];
        }
        reason = [mutableReason copy];
        matcherDetails = interactionError.userInfo[kErrorDetailElementMatcherKey];
      }

      GREYFrameworkException *exception =
          [GREYFrameworkException exceptionWithName:interactionError.domain
                                             reason:reason
                                           userInfo:interactionError.userInfo];

      id<GREYFailureHandler> failureHandler =
          [NSThread mainThread].threadDictionary[GREYFailureHandlerKey];

      [failureHandler handleException:exception details:matcherDetails];
    }
    return NO;
  } else {
    return YES;
  }
}

@end
