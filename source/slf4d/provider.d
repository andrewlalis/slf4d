/** 
 * Contains the specification for SLF4D providers to implement.
 */
module slf4d.provider;

import slf4d.factory;

/** 
 * This interface should be implemented by any logging provider, such that they
 * supply a LoggerFactory that will be used by an application.
 */
interface LoggingProvider {
    LoggerFactory getLoggerFactory();
}