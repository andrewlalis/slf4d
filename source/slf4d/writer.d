/**
 * This module defines the `SerializingLogHandler`, `LogWriter` interface, and
 * associated components for writing serialized log messages to external
 * systems.
 */
module slf4d.writer;

import slf4d;

/**
 * A component that serializes a log message into a string representation.
 */
interface LogSerializer {
    string serialize(immutable LogMessage msg);
}

/**
 * A log serializer that formats messages in the same way that SLF4D's default
 * provider does, which is <module> <level> <timestamp> <message>, roughly.
 */
class DefaultStringLogSerializer : LogSerializer {
    string serialize(immutable LogMessage msg) {
        import std.string;
        import slf4d.default_provider.formatters;
        string logStr = format!"%s %s %s %s"(
            formatLoggerName(msg.loggerName, false),
            formatLogLevel(msg.level, false),
            formatTimestamp(msg.timestamp, false),
            msg.message
        );
        if (!msg.exception.isNull) {
            logStr ~= "\n" ~ formatExceptionInfo(msg.exception.get(), false);
        }
        return logStr;
    }
}

/**
 * A log serializer that formats messages in a JSON string, containing all data
 * in the original log message struct.
 */
class JsonLogSerializer : LogSerializer {
    string serialize(immutable LogMessage msg) {
        import std.json;
        import slf4d.default_provider.formatters;
        JSONValue obj = JSONValue.emptyObject;
        obj.object["level"] = JSONValue.emptyObject;
        obj.object["level"].object["value"] = JSONValue(msg.level.value);
        obj.object["level"].object["name"] = JSONValue(msg.level.name);
        obj.object["message"] = JSONValue(msg.message);
        obj.object["timestamp"] = JSONValue(formatTimestamp(msg.timestamp, false));
        obj.object["loggerName"] = JSONValue(msg.loggerName);
        if (msg.exception.isNull) {
            obj.object["exception"] = JSONValue(null);
        } else {
            import slf4d.logger : ExceptionInfo;
            ExceptionInfo info = msg.exception.get();
            obj.object["exception"] = JSONValue.emptyObject;
            obj.object["exception"].object["message"] = JSONValue(info.message);
            obj.object["exception"].object["sourceFileName"] = JSONValue(info.sourceFileName);
            obj.object["exception"].object["sourceLineNumber"] = JSONValue(info.sourceLineNumber);
            obj.object["exception"].object["exceptionClassName"] = JSONValue(info.exceptionClassName);
            if (info.stackTrace.isNull()) {
                obj.object["exception"].object["stackTrace"] = JSONValue(null);
            } else {
                obj.object["exception"].object["stackTrace"] = JSONValue(info.stackTrace.get());
            }
        }
        obj.object["sourceContext"] = JSONValue.emptyObject;
        obj.object["sourceContext"].object["moduleName"] = JSONValue(msg.sourceContext.moduleName);
        obj.object["sourceContext"].object["functionName"] = JSONValue(msg.sourceContext.functionName);
        obj.object["sourceContext"].object["fileName"] = JSONValue(msg.sourceContext.fileName);
        obj.object["sourceContext"].object["lineNumber"] = JSONValue(msg.sourceContext.lineNumber);
        return obj.toString();
    }
}

/**
 * A strategy for determining what file to write to, when writing serialized
 * log messages to some output resource.
 */
interface LogFileStrategy {
    import std.stdio;
    ref File getFile();
}

/**
 * A log file strategy that simply always writes to a single file.
 */
class SingleLogFileStrategy : LogFileStrategy {
    import std.stdio;
    private File file;

    public this(File file) {
        this.file = file;
    }

    ref File getFile() {
        return cast(File) this.file;
    }
}

/**
 * A log file strategy that writes to a series of log files in a directory,
 * where a new file is used once a maximum file size is reached.
 */
class RotatingLogFileStrategy : LogFileStrategy {
    import std.stdio;
    import std.file;
    import std.path;
    import std.string;
    import std.algorithm;

    private File currentFile;
    private string logDir;
    private string logFilePrefix;
    private immutable ulong maxLogFileSize;

    public this(string logDir, string logFilePrefix = "log", ulong maxLogFileSize = 2_000_000_000) {
        this.logDir = logDir;
        this.logFilePrefix = logFilePrefix;
        this.maxLogFileSize = maxLogFileSize;
        this.initFile();
    }

    ref File getFile() {
        // Check if we need to close this file and open a new one.
        if (getSize(this.currentFile.name) > this.maxLogFileSize) {
            this.currentFile.close();
            this.currentFile = File(getNextFileName(), "a");
        }
        return this.currentFile;
    }

    private string getNextFileName() {
        import std.datetime;
        SysTime now = Clock.currTime();
        string filename = format!"%s_%04d-%02d-%02dT%02d-%02d-%02d.log"(
            this.logFilePrefix,
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second
        );
        return buildPath(this.logDir, filename);
    }

    private void initFile() {
        // If the log dir doesn't exist yet, make it and start a new file.
        if (!exists(this.logDir)) {
            mkdirRecurse(this.logDir);
            this.currentFile = File(getNextFileName(), "a");
        } else {// Otherwise, search for the best file to continue from.
            DirEntry[] potentialFilesToContinue;
            foreach (DirEntry entry; dirEntries(this.logDir, SpanMode.shallow, false)) {
                if (
                    entry.size() < this.maxLogFileSize &&
                    startsWith(baseName(entry.name), this.logFilePrefix)
                ) {
                    potentialFilesToContinue ~= entry;
                }
            }
            sort!((e1, e2) => e1.timeLastModified > e2.timeLastModified)(potentialFilesToContinue);
            if (potentialFilesToContinue.length > 0) {
                this.currentFile = File(potentialFilesToContinue[0].name, "a");
            } else {
                this.currentFile = File(getNextFileName(), "a");
            }
        }
    }
}

/**
 * A log writer is a component that writes a serialized log message string to
 * some output resource, like a file or network device.
 */
interface LogWriter {
    shared void write(string message);
}

/**
 * A log writer that writes messages to a file. The file that's used is
 * determined by the writer's `LogFileStrategy`. Some strategies may always use
 * the same file, and others may rotate log files, or overwrite old logs.
 */
class FileLogWriter : LogWriter {
    import std.stdio;

    private LogFileStrategy strategy;

    public this(LogFileStrategy strategy) {
        this.strategy = strategy;
    }

    shared void write(string message) {
        // Because this is a shared method, and our strategy isn't explicitly
        // shared, we synchronize access to it.
        File f;
        synchronized(this) {
            f = (cast(LogFileStrategy)this.strategy).getFile();
        }
        f.writeln(message);
        f.flush();
    }
}

/**
 * Writes logs to the standard output stream.
 */
class StdoutLogWriter : FileLogWriter {
    public this() {
        import std.stdio : stdout, File;
        super(new SingleLogFileStrategy(stdout));
    }
}

/**
 * A log handler that serializes incoming messages, and uses a `LogWriter` to
 * write them to some output resource, like a standard output stream, file, or
 * network device.
 */
class SerializingLogHandler : LogHandler {
    private shared LogSerializer serializer;
    private shared LogWriter writer;

    public shared this(LogSerializer serializer, LogWriter writer) {
        this.serializer = cast(shared(LogSerializer)) serializer;
        this.writer = cast(shared(LogWriter)) writer;
    }

    shared void handle(immutable LogMessage msg) {
        import std.stdio;
        try {
            // We need to cast away this serializer's `shared` attribute to call serialize.
            string rawMessage = (cast(LogSerializer) this.serializer).serialize(msg);
            try {
                this.writer.write(rawMessage);
            } catch (Exception e) {
                stderr.writefln!"Failed to write log message: %s"(e.msg);
            }
        } catch (Exception e) {
            stderr.writefln!"Failed to serialize log message: %s"(e.msg);
        }
    }
}

unittest {
    import slf4d;
    import slf4d.default_provider.factory;
    auto handler = new shared SerializingLogHandler(
        new JsonLogSerializer(),
        new FileLogWriter(new RotatingLogFileStrategy("test-logs"))
    );
    Logger logger = Logger(handler);
    logger.info("test");
    for (int i = 0; i < 1_000; i++) {
        logger.warn("This is a really long warning message that will clog up the files.");
    }
}
