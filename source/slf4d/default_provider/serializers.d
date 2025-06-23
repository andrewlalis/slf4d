/**
 * Defines several common default serializer implementations.
 */
module slf4d.default_provider.serializers;

import slf4d.level;
import slf4d.logger : LogMessage, ExceptionInfo;
import slf4d.writer;

import std.datetime : SysTime;

immutable size_t ISO8601_TIMESTAMP_LENGTH = 23;

/**
 * Log formatter that prints nicely formatted log messages to the console
 * without any particular structured format. It can apply ANSI colors to the
 * output.
 */
shared class ConsoleTextLogSerializer : LogSerializer {
    import std.string : rightJustify, leftJustify;
    import std.conv : to;

    private static immutable LOG_LEVEL_TEXT_WIDTH = 5; 

    private bool ansiColors;
    private size_t loggerNameLengthLimit;

    this(bool ansiColors = true, size_t loggerNameLengthLimit = 48) {
        this.ansiColors = ansiColors;
        this.loggerNameLengthLimit = loggerNameLengthLimit;
    }

    string serialize(immutable LogMessage msg) {
        string logStr = formatLoggerName(msg.loggerName) ~ " " ~
            formatLogLevel(msg.level) ~ " " ~
            formatTimestamp(msg.timestamp) ~ " " ~
            msg.message;
        if (!msg.exception.isNull()) {
            logStr ~= "\n" ~ formatExceptionInfo(msg.exception.get());
        }
        if (msg.attributes.length > 0) {
            logStr ~= "\n" ~ formatAttributes(msg.attributes);
        }
        return logStr;
    }

    protected string formatLoggerName(string name) {
        name = compactLoggerName(name);
        const size_t originalNameLength = name.length;
        if (ansiColors) {
            name = "\033[33m" ~ name ~ "\033[0m";
        }
        return rightJustify(name, loggerNameLengthLimit + (name.length - originalNameLength), ' ');
    }

    protected string compactLoggerName(string name) {
        import std.algorithm : splitter, map, count;
        import std.range;
        if (name.length <= loggerNameLengthLimit) return name;
        
        // See if we can split the name by dots to shorten it.
        auto parts = name.splitter('.');
        auto firstPart = parts.take(1);
        auto lastPart = parts.tail(1);
        auto middleParts = parts.drop(1).dropBack(1);
        if (!firstPart.empty && !lastPart.empty && !middleParts.empty) {
            size_t lengthWithAbbreviatedMiddleParts = firstPart.front.length +
                middleParts.count * 3 + 1 +
                lastPart.front.length;
            if (lengthWithAbbreviatedMiddleParts <= loggerNameLengthLimit) {
                return chain(firstPart, only("."), middleParts.map!(p => p[0] ~ "."), lastPart).join("");
            }
            // A basic abbreviation of the middle parts is too big, so now let's try to abbreviate the first part too.
            size_t lengthWithAllButLastAbbreviated = 1 + middleParts.count * 2 + 1 + lastPart.front.length;
            if (lengthWithAllButLastAbbreviated <= loggerNameLengthLimit) {
                return chain(only(firstPart.front[0] ~ "."), middleParts.map!(p => p[0] ~ "."), lastPart).join("");
            }
            // Even that's too big, so now we give up and just abbreviate using a simple ellipsis.
        }

        return "..." ~ name[3 + $ - loggerNameLengthLimit .. $];
    }

    protected string formatLogLevel(Level level) {
        string s = level.name;
        size_t originalLength = s.length;
        if (ansiColors) {
            string colorStr = "\033[1m";
            if (level == Levels.ERROR) {
                colorStr = "\033[31;1;4m";
            } else if (level == Levels.WARN) {
                colorStr = "\033[33;1m";
            } else if (level == Levels.INFO) {
                colorStr = "\033[34;1m";
            } else if (level == Levels.DEBUG) {
                colorStr = "\033[36;1m";
            } else if (level == Levels.TRACE) {
                colorStr = "\033[37;1m";
            } else {
                colorStr = "\033[34;1m"; // Use blue as a fallback for unknown levels.
            }
            s = colorStr ~ s ~ "\033[0m";
        }
        return leftJustify(s, LOG_LEVEL_TEXT_WIDTH + (s.length - originalLength), ' ');
    }

    protected string formatTimestamp(SysTime timestamp) {
        string s = formatTimestampISO8601(timestamp);
        if (ansiColors) {
            s = "\033[90m" ~ s ~ "\033[0m";
        }
        return s;
    }

    protected string formatExceptionInfo(ExceptionInfo info) {
        string exceptionName = info.exceptionClassName;
        if (ansiColors) {
            exceptionName = "\033[31;1m" ~ exceptionName ~ "\033[0m";
        }
        string sourceLocation = info.sourceFileName ~ ":" ~ to!string(info.sourceLineNumber);
        if (ansiColors) {
            sourceLocation = "\033[97;4m" ~ sourceLocation ~ "\033[0m";
        }
        string titleMessage = exceptionName ~ " thrown in " ~ sourceLocation ~ ": " ~ info.message;
        if (!info.stackTrace.isNull) {
            string traceStr = info.stackTrace.get();
            if (ansiColors) {
                traceStr = "\033[31m" ~ traceStr ~ "\033[0m";
            }
            titleMessage ~= "\n" ~ traceStr;
        }
        return titleMessage;
    }

    protected string formatAttributes(immutable(string[string]) attributes) {
        import std.range : repeat, array;
        size_t attributesIndentation = loggerNameLengthLimit + LOG_LEVEL_TEXT_WIDTH + ISO8601_TIMESTAMP_LENGTH + 3;
        string s;
        if (ansiColors) {
            s = repeat(' ', attributesIndentation).array.idup ~ "\033[4;37mAttributes:\033[0m";
        } else {
            s = repeat(' ', attributesIndentation).array.idup ~ "Attributes:";
        }
        foreach (key, value; attributes) {
            string keyStr = key;
            string valueStr = value;
            if (ansiColors) {
                keyStr = "\033[96m" ~ key ~ "\033[0m";
                valueStr = "\033[35m" ~ value ~ "\033[0m";
            }
            s ~= "\n" ~ repeat(' ', attributesIndentation + 2).array.idup ~ keyStr ~ " = " ~ valueStr;
        }
        return s;
    }
}

/**
 * A log serializer that formats messages in a JSON string, containing all data
 * in the original log message struct.
 */
class JsonLogSerializer : LogSerializer {
    string serialize(immutable LogMessage msg) shared {
        import std.json;
        JSONValue obj = JSONValue(string[string].init);
        obj.object["level"] = JSONValue(string[string].init);
        obj.object["level"].object["value"] = JSONValue(msg.level.value);
        obj.object["level"].object["name"] = JSONValue(msg.level.name);
        obj.object["message"] = JSONValue(msg.message);
        obj.object["timestamp"] = JSONValue(formatTimestampISO8601(msg.timestamp));
        obj.object["loggerName"] = JSONValue(msg.loggerName);
        if (msg.exception.isNull) {
            obj.object["exception"] = JSONValue(null);
        } else {
            import slf4d.logger : ExceptionInfo;
            ExceptionInfo info = msg.exception.get();
            obj.object["exception"] = JSONValue(string[string].init);
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
        obj.object["sourceContext"] = JSONValue(string[string].init);
        obj.object["sourceContext"].object["moduleName"] = JSONValue(msg.sourceContext.moduleName);
        obj.object["sourceContext"].object["functionName"] = JSONValue(msg.sourceContext.functionName);
        obj.object["sourceContext"].object["fileName"] = JSONValue(msg.sourceContext.fileName);
        obj.object["sourceContext"].object["lineNumber"] = JSONValue(msg.sourceContext.lineNumber);
        
        obj.object["attributes"] = JSONValue(string[string].init);
        foreach (key, value; msg.attributes) {
            obj.object["attributes"].object[key] = JSONValue(value);
        }

        return obj.toString();
    }
}

/**
 * Helper method to serialize a timestamp as an ISO-8601 datetime string, with
 * minimal GC allocation. The format is "YYYY-MM-DDTHH:MM:SS.sss".
 * Params:
 *   timestamp = The timestamp to format.
 * Returns: The formatted timestamp as a string.
 */
string formatTimestampISO8601(SysTime timestamp) {
    char[ISO8601_TIMESTAMP_LENGTH] buffer;
    writeZeroPaddedInt(buffer, 0, 4, timestamp.year);
    buffer[4] = '-';
    writeZeroPaddedInt(buffer, 5, 2, timestamp.month);
    buffer[7] = '-';
    writeZeroPaddedInt(buffer, 8, 2, timestamp.day);
    buffer[10] = 'T';
    writeZeroPaddedInt(buffer, 11, 2, timestamp.hour);
    buffer[13] = ':';
    writeZeroPaddedInt(buffer, 14, 2, timestamp.minute);
    buffer[16] = ':';
    writeZeroPaddedInt(buffer, 17, 2, timestamp.second);
    buffer[19] = '.';
    writeZeroPaddedInt(buffer, 20, 3, cast(int) timestamp.fracSecs.total!"msecs");
    return buffer.idup;
}

/** 
 * Writes a zero-padded integer to a character buffer, starting at the
 * specified index, and padding it to the specified length.
 * Params:
 *   buffer = The character buffer to write to.
 *   startIndex = The index in the buffer to start writing at.
 *   pad = The number of digits to pad the integer to.
 *   value = The integer value to write.
 */
private void writeZeroPaddedInt(char[] buffer, size_t startIndex, size_t pad, int value) {
    size_t index = startIndex + pad;
    while (value > 0 || pad > 0) {
        buffer[--index] = cast(char)('0' + (value % 10));
        value /= 10;
        --pad;
    }
    while (index > startIndex) {
        buffer[--index] = '0';
    }
}

unittest {
    char[10] buffer;
    writeZeroPaddedInt(buffer, 0, 3, 42);
    assert(buffer[0..3] == "042");
    writeZeroPaddedInt(buffer, 0, 5, 123);
    assert(buffer[0..5] == "00123");
    writeZeroPaddedInt(buffer, 0, 2, 7);
    assert(buffer[0..2] == "07");
}
