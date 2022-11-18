# ZebrunnerAgent

## Installation steps:
1. Add [package as dependency](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) to your project
2. In `Info.plist` or Xcode settings of Test Target (Info tab), add `Principal class` with value `ZebrunnerAgent.ZebrunnerObserver`
3. Once the principal class is added, the agent is **not** automatically enabled. The valid configuration must be provided.

It is currently possible to provide the configuration via:
1. Environment variables 
2. Info.plist properties file

The configuration lookup will be performed in the order listed above, meaning that environment configuration will always take precedence over Info.plist.

### Environment variables

If you are running the tests using `xcodebuild`, you have to perform some modifications to your Scheme for granting an access to provided environment variables. For the Scheme in Xcode (Xcode > Your Scheme > Edit Scheme > Test > Arguments tab > Environment Variables):

1. Add necessary environment variables as on the example below:

| Name                       | Value                         |
|----------------------------|-------------------------------|
| `REPORTING_ENABLED`        | `$(REPORTING_ENABLED)`        |
| `REPORTING_SERVER_HOSTNAME`| `$(REPORTING_SERVER_HOSTNAME)`|

2. Uncheck the "Use the Run action's arguments and environment variables"
3. Change the drop down "Expand Variables Based On" to the Test target in the Test scheme.


The following configuration parameters are recognized by the agent:
- `REPORTING_ENABLED` - enables or disables reporting. The default value is `false`;
- `REPORTING_SERVER_HOSTNAME` - mandatory if reporting is enabled. It is Zebrunner server base url (e.g. https://someproj.zebrunner.com);
- `REPORTING_SERVER_ACCESS_TOKEN` - mandatory if reporting is enabled. Access token must be used to perform API calls. It can be obtained in Zebrunner on the 'Account & profile' page under the 'Token' section;
- `REPORTING_PROJECT_KEY` - optional value. It is the project that the test run belongs to. The default value is `DEF`. You can manage projects in Zebrunner in the appropriate section;
- `REPORTING_RUN_DISPLAY_NAME` - optional value. It is the display name of the test run. The default value is `Default Suite`;
- `REPORTING_RUN_BUILD` - optional value. It is the build number that is associated with the test run. It can depict either the test build number or the application build number;
- `REPORTING_RUN_ENVIRONMENT` - optional value. It is the environment where the tests will run;
- `REPORTING_RUN_LOCALE` - optional value. Locale, that will be displayed for the run in Zebrunner if specified;
- `REPORTING_RUN_TREAT_SKIPS_AS_FAILURES` - optional value. The default value is `true`. If the value is set to `true`, skipped tests will be treated as failures when processing test run results. As a result, if value of the property is set to `false` and test run contains only skipped and passed tests, the entire test run will be treated as passed;
- `REPORTING_NOTIFICATION_NOTIFY_ON_EACH_FAILURE` - optional value. Specifies whether Zebrunner should send notification to Slack/Teams on each test failure. The notifications will be sent even if the suite is still running. The default value is `false`;
- `REPORTING_NOTIFICATION_SLACK_CHANNELS` - optional value. The list of comma-separated Slack channels to send notifications to. Notification will be sent only if Slack integration is properly configured in Zebrunner with valid credentials for the project the tests are reported to. Zebrunner can send two type of notifications: on each test failure (if appropriate property is enabled) and on suite finish;
- `REPORTING_NOTIFICATION_MS_TEAMS_CHANNELS` - optional value. The list of comma-separated Microsoft Teams channels to send notifications to. Notification will be sent only if Teams integration is configured in Zebrunner project with valid webhooks for the channels. Zebrunner can send two type of notifications: on each test failure (if appropriate property is enabled) and on suite finish;
- `REPORTING_NOTIFICATION_EMAILS` - optional value. The list of comma-separated emails to send notifications to. This type of notification does not require further configuration on Zebrunner side. Unlike other notification mechanisms, Zebrunner can send emails only on suite finish;
- `REPORTING_MILESTONE_ID` - optional value. Id of the Zebrunner milestone to link the suite execution to. The id is not displayed on Zebrunner UI, so the field is basically used for internal purposes. If the milestone does not exist, appropriate warning message will be displayed in logs, but the test suite will continue executing;
- `REPORTING_MILESTONE_NAME` - optional value. Name of the Zebrunner milestone to link the suite execution to. If the milestone does not exist, appropriate warning message will be displayed in logs, but the test suite will continue executing;
- `REPORTING_DEBUG_LOGS_ENABLED` - optional value. The default value is `false` that means that debugging functions from Swift Standard Library such as `print, debugPrint and dump` will not be displayed in log output.

### Info.plist properties

Unlike environment variables, Info.plist files are separate for each Test Target and you could apply different Zebrunner settings for them. For example, turn off reporting for Unit tests and enable for UI tests.

The following configuration parameters are recognized by the agent:
- `ReportingEnabled` - enables or disables reporting. The default value is `false`;
- `ReportingServerHostname` - mandatory if reporting is enabled. It is Zebrunner server base url (e.g. https://someproj.zebrunner.com);
- `ReportingServerAccessToken` - mandatory if reporting is enabled. Access token must be used to perform API calls. It can be obtained in Zebrunner on the 'Account & profile' page under the 'Token' section;
- `ReportingProjectKey` - optional value. It is the project that the test run belongs to. The default value is `DEF`. You can manage projects in Zebrunner in the appropriate section;
- `ReportingRunDisplayName` - optional value. It is the display name of the test run. The default value is `Default Suite`;
- `ReportingRunBuild` - optional value. It is the build number that is associated with the test run. It can depict either the test build number or the application build number;
- `ReportingRunEnvironment` - optional value. It is the environment where the tests will run;
- `ReportingRunLocale` - optional value. Locale, that will be displayed for the run in Zebrunner if specified;
- `ReportingRunTreatSkipsAsFailures` - optional value. The default value is `true`. If the value is set to `true`, skipped tests will be treated as failures when processing test run results. As a result, if value of the property is set to `false` and test run contains only skipped and passed tests, the entire test run will be treated as passed;
- `ReportingNotificationNotifyOnEachFailure` - optional value. Specifies whether Zebrunner should send notification to Slack/Teams on each test failure. The notifications will be sent even if the suite is still running. The default value is `false`;
- `ReportingNotificationSlackChannels` - optional value. The list of comma-separated Slack channels to send notifications to. Notification will be sent only if Slack integration is properly configured in Zebrunner with valid credentials for the project the tests are reported to. Zebrunner can send two type of notifications: on each test failure (if appropriate property is enabled) and on suite finish;
- `ReportingNotificationMsTeamsChannels` - optional value. The list of comma-separated Microsoft Teams channels to send notifications to. Notification will be sent only if Teams integration is configured in Zebrunner project with valid webhooks for the channels. Zebrunner can send two type of notifications: on each test failure (if appropriate property is enabled) and on suite finish;
- `ReportingNotificationEmails` - optional value. The list of comma-separated emails to send notifications to. This type of notification does not require further configuration on Zebrunner side. Unlike other notification mechanisms, Zebrunner can send emails only on suite finish;
- `ReportingMilestoneId` - optional value. Id of the Zebrunner milestone to link the suite execution to. The id is not displayed on Zebrunner UI, so the field is basically used for internal purposes. If the milestone does not exist, appropriate warning message will be displayed in logs, but the test suite will continue executing;
- `ReportingMilestoneName` - optional value. Name of the Zebrunner milestone to link the suite execution to. If the milestone does not exist, appropriate warning message will be displayed in logs, but the test suite will continue executing;
- `ReportingDebugLogsEnabled` - optional value. The default value is `false` that means that debugging functions from Swift Standard Library such as `print, debugPrint and dump` will not be displayed in log output.


## Useful classes
1. `Artifact` - you can use static methods from this class to add artifacts and references to test cases and test runs
2. `Label` - you can use static methods from this class to add Labels to test cases and test runs
3. `Locale` - provides a method to add a locale to test run
4. `Log` - provides a possibility to send log messages to test case
3. `Screenshot` - helps when you need to attach a screenshot to test case

## Test maintainer
If you wish to assign a test maintainer for your test case, you can set maintainer's Zebrunner username value to `testMaintainer` variable in test case:
```
func testSmth() {
    testMaintainer = "dprymudrau"
    
    let app = XCUIApplication()
    app.launch()
    ...
}
```

## Screenshots
You can take a screenshot of current device screen everywhere in your test class (that extends XCTestCase) that will be automatically attached to XCTest report and sent to Zebrunner:
```
func testSmth() {
    let app = XCUIApplication()
    app.launch()
    
    takeScreenshot()
    ...
}
```

or you can perform taking a custom screenshot (e.g. single UI element) and attach it to the reports above:

```
func testSmth() {
    let firstNameTextFieldScreenshot = XCUIApplication().textFields["firstName"].screenshot()
    takeScreenshot(screenshot: firstNameTextFieldScreenshot)
    ...
}
```

In case of sending a screenshot of failed test automatically to Zebrunner, extends your test class from `ZebrunnerBaseTestCase`. Functionality mentioned above will still work.

## Logs
Zebrunner agent intercepts your console output for a certain test case and sends captured logs to Zebrunner.

_Which types of log messages are intercepted:_
1. default XCTest/XCUITest logging (like "Tap button", "Checking existence of" etc.)
2. custom logging using "NSLog"
3. custom unified logging: "Logger" interface from "os" module and "os_log" from "os.log"

_Not intercepted if REPORTING_DEBUG_LOGS_ENABLED/ReportingDebugLogsEnabled is `false`:_
Debugging functions from Swift Standard Library: print, debugPrint and dump.

All log types above are intercepted if _REPORTING_DEBUG_LOGS_ENABLED/ReportingDebugLogsEnabled is `true`_
