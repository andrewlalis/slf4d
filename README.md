<img
    src="https://github.com/andrewlalis/slf4d/blob/main/design/banner_1024.png"
    alt="SLF4D Banner Image"
    style="max-width: 300px"
/>

# SLF4D

![DUB](https://img.shields.io/dub/v/slf4d?color=%23c10000ff%20&style=flat-square) ![DUB](https://img.shields.io/dub/dt/slf4d?style=flat-square) ![DUB](https://img.shields.io/dub/l/slf4d?style=flat-square) ![GitHub Workflow Status (with branch)](https://img.shields.io/github/actions/workflow/status/andrewlalis/slf4d/run-tests.yml?branch=main&label=tests&style=flat-square)

Simple Logging Facade for D, inspired by SLF4J. `dub add slf4d`, and start logging sensibly!

[Read the full documentation here!](https://andrewlalis.github.io/slf4d/)

SLF4D acts as a common interface for logging messages during an application's runtime. Let's see an example of how you can use it:

```d
import slf4d;

void main() {
    info("Hello world!");
    try {
        int result = doStuff();
        infoF!"Result = %d"(result);
    } catch (Exception e) {
        error("Failed to do stuff.", e);
    }
}
```

> Output:
> ```
> app INFO  2023-05-05T15:50:46.087 Hello world!
> app INFO  2023-05-05T15:50:46.087 Result = 84
> ```
>
> In this example, we're implicitly using SLF4D's [DefaultProvider](https://andrewlalis.github.io/slf4d/ddoc/slf4d.default_provider.provider.DefaultProvider.html) to log messages using some of the available [log functions](https://andrewlalis.github.io/slf4d/ddoc/slf4d.log_functions.html).
>
> Also note the log message format of `<module> <level> <timestamp> <message>`. This is just how the default provider formats messages, but the format is entirely customizable using a different provider.



## Usage

To start using SLF4D in your project, all you need to do is add it as a dependency to your dub project, and `import slf4d;` wherever you need it.

Consider checking out [examples/basic-usage](https://github.com/andrewlalis/slf4d/tree/main/examples/basic-usage) for a quick overview, if you don't fancy reading.

### Log Functions

The following table gives an overview of the functions that are available when you `import slf4d;`
| Level | Basic | Formatted |
|---    |---    |---        |
| TRACE | `trace("Message")` | `traceF!"Message %d"(42)` |
| DEBUG | `debug_("Message")`* | `debugF!"Message %d"(42)` |
| INFO | `info("Message")` | `infoF!"Message %d"(42)` |
| WARN | `warn("Message")` | `warnF!"Message %d"(42)` |
| ERROR | `error("Message")` | `errorF!"Message %d"(42)` |
> \* Because `debug` is a keyword in D, `debug_` is used as the function name.

Each function can also accept an `Exception` after its usual message or arguments, and it'll include it in the log message. Third-party providers can even configure additional logic for what to do if an exception is logged.

```d
try {
    doSomethingDangerous();
} catch (Exception e) {
    warn("Uh oh, something went wrong.", e);
    error(e); // Or let SLF4D use the exception's message
}
```

### Loggers

Behind the scenes, the role of the _Logging Provider_ is to provide SLF4D with a [Logger](https://andrewlalis.github.io/slf4d/ddoc/slf4d.logger.Logger.html) to forward any of the above log function calls to. Therefore, direct logging calls are just a convenient way of doing the following:

```d
Logger logger = getLogger();
logger.info("Hello world!");

// The above code is equivalent to this:
info("Hello world!");
```

Usually, this distinction won't matter at all, but it's mentioned here for completeness' sake. However, Loggers enable you to override the logger's name, which defaults to the current D module's name. Suppose you want a logger whose name is `Test Logs`; then you should call your log functions on a Logger with that name:

```d
Logger logger = getLogger("Test Logs");
logger.warn("A message");
```

### Configuring the Provider

By default, SLF4D uses a built-in logging provider that simply writes log messages to stdout and stderr. However, if you'd like to use a third-party logging provider instead, or create your own custom provider, all you need to do is call `configureLoggingProvider()` when your application starts, to set the logging provider to use.

```d
import slf4d;
import some_slf4d_provider;

void main() {
    configureLoggingProvider(new CustomProvider());
    info("This message is handled by the custom provider!");
}
```

### Builders

In addition to the log functions described above, the Logger also provides a set of _builder_ methods that give you a [LogBuilder](https://andrewlalis.github.io/slf4d/ddoc/slf4d.logger.LogBuilder.html) with a fluent interface for building log messages.

```d
Logger logger = getLogger();
logger.warnBuilder()
    .msg("Building a warning message...")
    .exc(new Exception("Oh no!"))
    .log();
```

### Testing

SLF4D is designed to be easy-to-use in unit testing, and it comes with a few purpose-built components to facilitate this.

- The [slf4d.testing_provider](https://andrewlalis.github.io/slf4d/ddoc/slf4d.testing_provider.html) package defines a `TestingLoggingProvider` class that be used to help with recording any log messages that were sent to it.
- Under the hood, it uses a `CachingLogHandler` from `slf4d.handler` which is a thread-safe handler for storing logged messages in memory for inspection.
- You can configure it yourself, or simply call `getTestingProvider()` from within a unittest block.

Here's an example.

```d
unittest {
    import slf4d;
    import slf4d.test;

    withTestingProvider((provider) {
        callMySystemUnderTest();

        provider.assertMessageCount(3);
        provider.assertHasMessage("Hello world!");
        assert(provider.messages[0].level == Levels.INFO);
        assert(provider.messages[1].message == "Hello world!");

        // Reset the testing provider to clear all log messages.
        provider.reset();

        callMyOtherSystemUnderTest();

        // Check that there are no warn/error messages.
        provider.assertNoMessages(Levels.WARN);
        provider.assertNoMessages(Levels.ERROR);
    });
}
```

## Making a Custom Provider

To create a logging provider, simply implement the `LoggingProvider` interface defined in `slf4d.provider`. Consider using a mutex or `synchronized` in your handler or factory if it needs to access a shared resource.

Check out [examples/custom-provider](https://github.com/andrewlalis/slf4d/tree/main/examples/custom-provider) for an example of how you can create such a logging provider.

## Why SLF4D?

First, let me ask a question: Is there a single unanimously chosen logging library for the D language? Currently, that answer is "**no**", and as long as it stays like that, and I imagine it will, then SLF4D can be of use.

SLF4D **is not a logger** itself, but a common interface that any library or end-user application can plug into. The goal is to allow anyone to support structured logging in their D project, while giving developers the freedom to choose how log messages are handled when you go to run your program. By logging with SLF4D, you make your D modules' log messages compatible with all available logging providers.

D developers; if this message resonates with you, consider adding SFL4D logging to your project!

## Versioning

The versioning of SLF4D follows the [Semantic Versioning](https://semver.org/) principles which are, in short:
- Version numbers formatted as `<Major>.<Minor>.<Patch>`, e.g. `1.2.3`
- Major version increases when an incompatible change is introduced.
- Minor version increases when backwards-compatible functionality is introduced.
- Patch version increases when backwards-compatible bug-fixes are introduced.

More specifically in the context of this library, major version upgrades **may** introduce a breaking change to either the logging interface or the provider/message handling, but all breaking changes and incompatibilities **must** be defined in a changelog file for each release. See the [changelogs](https://github.com/andrewlalis/slf4d/tree/main/changelogs) directory for the comprehensive list of all changelogs.
