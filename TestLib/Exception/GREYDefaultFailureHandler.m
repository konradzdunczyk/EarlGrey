//
// Copyright 2017 Google Inc.
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

#import "GREYDefaultFailureHandler.h"

#import <XCTest/XCTest.h>

#import "GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "GREYFailureScreenshotter.h"
#import "NSFileManager+GREYCommon.h"
#import "GREYThrowDefines.h"
#import "GREYConfiguration.h"
#import "GREYErrorConstants.h"
#import "GREYFrameworkException.h"
#import "GREYFailureFormatter.h"
#import "GREYFailureScreenshotSaver.h"
#import "XCTestCase+GREYTest.h"
#import "GREYElementHierarchy.h"

// Counter that is incremented each time a failure occurs in an unknown test.
@implementation GREYDefaultFailureHandler {
  NSString *_fileName;
  NSUInteger _lineNumber;
  id _currentTestCase;
}

#pragma mark - GREYFailureHandler

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  _fileName = fileName;
  _lineNumber = lineNumber;
}

- (void)setCurrentTestCase:(id)testCase {
  _currentTestCase = testCase;
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)matcherDetails {
  GREYThrowOnNilParameter(exception);
  id currentTestCase = [XCTestCase grey_currentTestCase];

  NSMutableString *logMessage = [[NSMutableString alloc] init];
  NSString *reason = exception.reason;

  if (reason.length == 0) {
    reason = @"exception.reason was not provided";
  }

  [logMessage
      appendString:[NSString stringWithFormat:@"%@: %@", @"Exception Name", exception.name]];
  [logMessage appendString:[NSString stringWithFormat:@"\n%@: %@", @"Exception Reason", reason]];

  if (matcherDetails.length > 0) {
    [logMessage
        appendString:[NSString stringWithFormat:@"\n%@: %@", @"Element Matcher", matcherDetails]];
  }

  NSDictionary *appScreenshots = [exception.userInfo valueForKey:kErrorDetailAppScreenshotsKey];
  // Re-obtain the screenshots when a user might be using GREYAsserts. Since this is from the test
  // process, the delay here would be minimal.
  if (!appScreenshots) {
    appScreenshots = [GREYFailureScreenshotter screenshots];
  }

  NSString *uniqueSubDirName =
      [NSString stringWithFormat:@"%@-%@", exception.name, [[NSUUID UUID] UUIDString]];
  __unused NSString *screenshotDir = [GREY_CONFIG_STRING(kGREYConfigKeyArtifactsDirLocation)
      stringByAppendingPathComponent:uniqueSubDirName];
  __unused NSArray<NSString *> *screenshots =
      [GREYFailureScreenshotSaver saveFailureScreenshotsInDictionary:appScreenshots
                                                         toDirectory:screenshotDir];
  NSAssert(screenshots, @"Screenshots must be present");
  NSArray *stackTrace = [NSThread callStackSymbols];

  NSString *appUIHierarchy = [exception.userInfo valueForKey:kErrorDetailAppUIHierarchyKey];
  // For calls from GREYAsserts in the test side, the hierarchy must be populated here.
  if (!appUIHierarchy) {
    appUIHierarchy = [GREYElementHierarchy hierarchyString];
  }

  NSString *log = [GREYFailureFormatter formatFailureForTestCase:currentTestCase
                                                    failureLabel:@"Exception"
                                                     failureName:exception.name
                                                        filePath:_fileName
                                                      lineNumber:_lineNumber
                                                    functionName:nil
                                                      stackTrace:stackTrace
                                                  appScreenshots:appScreenshots
                                                       hierarchy:appUIHierarchy
                                                          format:@"%@", logMessage];
  [currentTestCase grey_markAsFailedAtLine:_lineNumber inFile:_fileName description:log];
}

@end
