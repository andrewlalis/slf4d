# SLF4D
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

## Configuring the Provider

By default, SLF4D uses a built-in logging provider that simply writes log messages to stdout and stderr. However, if you'd like to use a third-party logging provider instead, or create your own custom provider, all you need to do is call `configureLoggingProvider()` when your application starts, to set the shared logging provider to use.

```d
import slf4d;
import some_slf4d_provider;

void main() {
    configureLoggingProvider(new shared CustomProvider());
}
```

## Making a Custom Provider

To create a logging provider, simply implement the `LoggingProvider` interface defined in `slf4d.provider`. Note that your logging factory and handler should be `shared`, that is, they will be shared among all threads of an application which uses your provider.
