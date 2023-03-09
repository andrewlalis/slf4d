# Introduction

SLF4D stands for _Simple Logging Facade for D_, but what does that mean? Well, put briefly, it's a _frontend_ for logging, with a configurable _backend_ for handling log messages. This means that many different libraries can all use SLF4D, while letting the end-user decide how they want log messages to be processed.

Suppose I've made my own D library, and I want to add logging to it. I can use SLF4D like so:

```d
module my_lib;

import slf4d;

void myComplexFunction(int x) {
    debugF!"Doing some complex stuff with %d."(x);
    // Do stuff below here...
}
```

Then when I go to make an app using `my_lib`, I can configure logging _once_ in my app, and any modules using SLF4D will have their messages handled according to my configuration:

```d
module my_app;

import slf4d;
import slf4d.default_provider;
import my_lib;

void main() {
    // In this example, we'll just be using SLF4D's default logging provider
    // but you can use any SLF4D provider.
    auto provider = new shared DefaultProvider(true, Levels.DEBUG);
    configureLoggingProvider(provider);

    myComplexFunction(42);
}
```

This short example illustrates the main purposes of SLF4D:
- **Simplify the logging interface for developers**
- **Give the end-user complete control over their log messages**
