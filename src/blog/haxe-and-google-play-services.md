@name = Haxe and Google Play Services
@slug = play-haxe
@published = 2014-10-07

Recently I decided I wanted to integrate Google Play Services -- leaderboards, achievements, etc -- with a Haxe/OpenFL project targetting Android devices. I assumed this should be easy enough given the ability to hook into Android/Java frameworks via native extensions. Overall it was simple, but not necessarily straightforward, so I'm writing this post as a quick start guide for others.

### Setting Up Project Extensions

I settled on using the [linden-google-play](https://github.com/sergey-miryanov/linden-google-play) extension, which sets up the JNI hooks to the Play Services library for you.

Install it via:

    haxelib git linden-google-play https://github.com/sergey-miryanov/linden-google-play

and it will be made available to projects globally. Include it in your OpenFL project's `project.xml` with:

```xml
<haxelib name="openfl" />
<haxelib name="linden-google-play" if="android" />
<!-- You will need to include an Android manifest as well. I'll describe this soon. -->
<template path="AndroidManifest.xml" if="android" />
```

Finally you can import the Haxe classes as:

```haxe
#if (android)
import ru.zzzzzzerg.linden.GooglePlay;
#end
```

Usage is fairly straightforward, assuming that your project is set up correctly. If not, you may get odd behavior without much to help you diagnose the problem. The [linden-samples](https://github.com/sergey-miryanov/linden-samples) project on github has several examples that will get you started.

### Android App Setup

There are several gotchas here:

__Register your app in the Google Play Services dashboard.__

This involves using `keytool` (part of the Android NDK)

__APP_ID must be correctly embedded in your app resources (@id/string)__

In your `project.xml`:

```xml
<template path="ids.xml" rename="res/values/ids.xml" if="android" />
<template path="AndroidManifest.xml" if="android" />
```


And then in the same directory, named `ids.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <string name="app_id">YOUR_APP_ID</string>
  <integer name="google_play_services_version">4030500</integer>
</resources>
```

The app id is listed when you create your play services hooks from the online dashboard.

__Make sure you are using a currently supported jar of the Play Services library__

You may need to replace the jar within the `linden-google-play` extension with a newer version.

__Make sure your app is being signed correctly.__

If you use the debug android keystore to generate the hash that the play services console requires (for registration,) make sure you also use that keystore to sign your app. Lime should use this by default if you are testing using `lime android test` from the commandline.

If you need to specify the alias for the keystore, `debug` may be used by default, but mine was created with the alias `androiddebugkey`. You can find this by running `keytool -list -keystore /path/to/debug.keystore` (mine was in `~/.android`). If you are using the default, the password should be `debug`.

If you need to have lime use another keystore:

```xml
<certificate path="/path/to/keystore" alias="your_key_alias" if="android" />
```

__Put in debug prints with error codes:__

I had difficulty connecting with `linden-google-play` at first, and found it helpful to insert traces within `play/ConnectionHandler.hx`. Printing the `code` in `onError` can provide useful information.

Additionally, it may be helpful to use `logcat`, the standard android development logging tool. It is located within the android sdk distribution, by running `./sdk/platform-tools/adb logcat`.

You'll get a lot of information this way; I found it most helpful to filter it: `adb logcat | grep Game`. This is a good way to find out if your app does not match the signature you submitted to google play, or other common issues.

### Conclusion

In short there are a lot of moving parts that go into making this process simple in some respects like being able to integrate extensions and external APIs. This means there are many issues that can arise, even with a high degree of dilligence.

Hopefully this tutorial will help others, or at least save them some time in consolidating this information! Good luck.
