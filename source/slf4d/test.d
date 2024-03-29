/**
 * The test module defines some common components and imports that are useful
 * for testing your application's logging behavior.
 *
 * Do not import this module outside the scope of any test code/unittests, as
 * it may interfere with normal SLF4D operations.
 */
module slf4d.test;

import core.sync.mutex;

/** 
 * A convenience import of the main SLF4D package.
 */
public import slf4d;

/** 
 * Imports the testing provider, since that's needed for most SLF4D-related tests.
 */
public import slf4d.testing_provider;

/** 
 * A mutex to synchronize tests that affect the core logging state. You can
 * either synchronize on this object, or call `acquireLoggingTestingLock()` to
 * ensure that only your test has access to the logging state. Be sure that if
 * you acquire a testing lock, that you release it afterwards with
 * `releaseLoggingTestingLock()`.
 */
public __gshared Mutex loggingTestingMutex;

static this() {
    loggingTestingMutex = new Mutex();
}

/** 
 * Acquires a lock for the SLF4D testing system. Call this before testing
 * anything which interacts with a pre-configured testing setup for logging.
 */
public void acquireLoggingTestingLock() {
    loggingTestingMutex.lock_nothrow();
}

/** 
 * Releases a lock for the SLF4D testing system. Call this after testing
 * anything that required the lock to be acquired.
 */
public void releaseLoggingTestingLock() {
    loggingTestingMutex.unlock_nothrow();
}

/** 
 * Resets the SLF4D logging state, and configures a new TestingLoggingProvider
 * to be used, and returns it. This should only be called when you've acquired
 * a lock for the testing system (or synchronized on the mutex).
 * Returns: The logging provider.
 */
public TestingLoggingProvider getTestingProvider() {
    resetLoggingState();
    TestingLoggingProvider testingProvider = new TestingLoggingProvider();
    configureLoggingProvider(testingProvider);
    return testingProvider;
}

/**
 * Convenience function to acquire a lock on the SLF4D logging state and run
 * some code, then reset the logging state and release the lock.
 * Params:
 *   dg = The code to run.
 */
public void withTestingLock(void delegate() dg) {
    acquireLoggingTestingLock();
    dg();
    resetLoggingState();
    releaseLoggingTestingLock();
}

/**
 * Convenience function to acquire a lock on the testing state, run some code
 * (in the provided delegate function), then release the lock.
 * Params:
 *   dg = The code to run with the testing logging provider.
 */
public void withTestingProvider(void delegate(TestingLoggingProvider) dg) {
    acquireLoggingTestingLock();
    dg(getTestingProvider());
    resetLoggingState();
    releaseLoggingTestingLock();
}
