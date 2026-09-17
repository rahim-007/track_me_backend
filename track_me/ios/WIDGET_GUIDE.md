# iOS WidgetKit Setup Guide for UrDay

This guide explains how to activate the UrDay Home Screen Widgets on iOS using Xcode.

## 1. Add Widget Extension in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select **File > New > Target...**.
3. Choose **Widget Extension** under iOS.
4. Set:
   - **Product Name**: `UrDayWidgets`
   - **Include Live Activity**: Unchecked (optional)
   - **Include Configuration Intent**: Unchecked
5. Click **Finish**. When prompted to activate scheme, click **Activate**.

## 2. Configure App Groups (Required for Data Sharing)

1. Select the **Runner** project in the Xcode project navigator.
2. Select the **Runner** target > **Signing & Capabilities**.
3. Click **+ Capability** and add **App Groups**.
4. Click **+** under App Groups and enter:
   `group.com.trackme.app`
5. Now select the **UrDayWidgetsExtension** target > **Signing & Capabilities**.
6. Click **+ Capability** and add **App Groups**.
7. Check the same group:
   `group.com.trackme.app`

## 3. Replace Widget Code

1. Locate the newly created `UrDayWidgets.swift` in the `UrDayWidgets` folder in Xcode.
2. Replace its contents with the code from [`ios/UrDayWidgets.swift`](file:///c:/Users/Rahim/OneDrive/Desktop/Track%20me%201/track_me/ios/UrDayWidgets.swift).

## 4. Deep Link Scheme Configuration

In `ios/Runner/Info.plist`, verify or add the URL scheme:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>urday</string>
        </array>
    </dict>
</array>
```

## 5. Build and Run

Run on an iOS 16+ Simulator or device, long press the Home Screen, tap `+`, search for **UrDay**, and add the Small or Medium widget!
