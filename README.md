<img
    src="https://github.com/andrewlalis/slf4d/blob/main/design/banner_1024.png"
    alt="SLF4D Banner Image"
    style="max-width: 300px"
/>

# SLF4D

![DUB](https://img.shields.io/dub/v/slf4d?color=%23c10000ff%20&style=flat-square) ![DUB](https://img.shields.io/dub/dt/slf4d?style=flat-square) ![DUB](https://img.shields.io/dub/l/slf4d?style=flat-square) ![GitHub Workflow Status (with branch)](https://img.shields.io/github/actions/workflow/status/andrewlalis/slf4d/run-tests.yml?branch=main&label=tests&style=flat-square)

Simple Logging Facade for D, inspired by SLF4J. Add it to your project with `dub add slf4d`, and start logging sensibly!

SLF4D provides a common interface and core logging features, while allowing third-party providers to handle log messages produced at runtime. Take a look at the following example, where we get a logger from SLF4D and write an *info* message.

```d
import slf4d;

void main() {
    auto log = getLogger();
    log.info("Hello world!");
}
```

You can also define a module-level logger instead, using a `static this` initializer:

```d
import slf4d;

private Logger log;
static this {
    log = getLogger();
}

void main() {
    log.info("Hello world!");
}
```

## Logging Methods

The following table gives a brief outline of the available logging methods provided by an SLF4D `Logger` struct obtained via `log = getLogger();`
| Level | Basic | Formatted | Builder |
|---    |---    |---        |---      |
| TRACE | `log.trace("Message")` | `log.traceF!"Message %d"(42)` |
| DEBUG | `log.debug_("Message")`* | `log.debugF!"Message %d"(42)` |
| INFO | `log.info("Message")` | `log.infoF!"Message %d"(42)` |
| WARN | `log.warn("Message")` | `log.warnF!"Message %d"(42)` |
| ERROR | `log.error("Message")` | `log.errorF!"Message %d"(42)` |
> \* Because `debug` is a keyword in D, `debug_` is used as the method name.

## Configuring the Provider

By default, SLF4D uses a built-in logging provider that simply writes log messages to stdout and stderr. However, if you'd like to use a third-party logging provider instead, or create your own custom provider, all you need to do is call `configureLoggingProvider()` when your application starts, to set the shared logging provider to use.

```d
import slf4d;
import some_slf4d_provider;

void main() {
    configureLoggingProvider(new shared CustomProvider());
    auto log = getLogger(); // Logger configured using provider.
}
```

## Testing

SLF4D is designed to be easy-to-use in unit testing, and it comes with a few purpose-built components to facilitate this.

- The `slf4d.testing_provider` package defines a `TestingLoggingProvider` class that be used to help with recording any log messages that were sent to it.
- Under the hood, it uses a `CachingLogHandler` from `slf4d.handler` which is a thread-safe handler for storing logged messages in memory for inspection.

Here's an example.

```d
unittest {
    import slf4d;
    import slf4d.testing_provider;
    // Setup SLF4D using our testing provider.
    auto provider = new shared TestingLoggingProvider();
    configureLoggingProvider(provider);

    callMySystemUnderTest();

    assert(provider.messages.length == 3);
    assert(provider.messages[0].level == Levels.INFO);
    assert(provider.messages[1].message == "Hello world!");

    // Reset the testing provider to clear all log messages.
    provider.reset();

    callMyOtherSystemUnderTest();

    // Check that there are no warn/error messages.
    foreach (msg; provider.messages) {
        assert(msg.level.value < Levels.WARN.value);
    }
}
```

## Making a Custom Provider

To create a logging provider, simply implement the `LoggingProvider` interface defined in `slf4d.provider`. Note that your logging factory and handler should be `shared`, that is, they will be shared among all threads of an application which uses your provider. Consider using a mutex or `synchronized` in your handler or factory if it needs to access a shared resource.

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
