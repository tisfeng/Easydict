//
//  MMCrashSignalExceptionHandler.m
//  MMKit
//
//  Created by wenquan on 2018/11/22.
//

#import "MMCrashSignalExceptionHandler.h"

#import <execinfo.h>

#import "MMCrashFileTool.h"

typedef void (*SignalHandler)(int signal, siginfo_t *info, void *context);

static SignalHandler previousABRTSignalHandler = NULL;
static SignalHandler previousBUSSignalHandler = NULL;
static SignalHandler previousFPESignalHandler = NULL;
static SignalHandler previousILLSignalHandler = NULL;
static SignalHandler previousPIPESignalHandler = NULL;
static SignalHandler previousSEGVSignalHandler = NULL;
static SignalHandler previousSYSSignalHandler = NULL;
static SignalHandler previousTRAPSignalHandler = NULL;


@implementation MMCrashSignalExceptionHandler

#pragma mark - Register

+ (void)registerHandler {
    // Backup original handler
    [self backupOriginalHandler];

    [self signalRegister];
}

+ (void)backupOriginalHandler {
    struct sigaction old_action_abrt;
    sigaction(SIGABRT, NULL, &old_action_abrt);
    if (old_action_abrt.sa_sigaction) {
        previousABRTSignalHandler = old_action_abrt.sa_sigaction;
    }

    struct sigaction old_action_bus;
    sigaction(SIGBUS, NULL, &old_action_bus);
    if (old_action_bus.sa_sigaction) {
        previousBUSSignalHandler = old_action_bus.sa_sigaction;
    }

    struct sigaction old_action_fpe;
    sigaction(SIGFPE, NULL, &old_action_fpe);
    if (old_action_fpe.sa_sigaction) {
        previousFPESignalHandler = old_action_fpe.sa_sigaction;
    }

    struct sigaction old_action_ill;
    sigaction(SIGILL, NULL, &old_action_ill);
    if (old_action_ill.sa_sigaction) {
        previousILLSignalHandler = old_action_ill.sa_sigaction;
    }

    struct sigaction old_action_pipe;
    sigaction(SIGPIPE, NULL, &old_action_pipe);
    if (old_action_pipe.sa_sigaction) {
        previousPIPESignalHandler = old_action_pipe.sa_sigaction;
    }

    struct sigaction old_action_segv;
    sigaction(SIGSEGV, NULL, &old_action_segv);
    if (old_action_segv.sa_sigaction) {
        previousSEGVSignalHandler = old_action_segv.sa_sigaction;
    }

    struct sigaction old_action_sys;
    sigaction(SIGSYS, NULL, &old_action_sys);
    if (old_action_sys.sa_sigaction) {
        previousSYSSignalHandler = old_action_sys.sa_sigaction;
    }

    struct sigaction old_action_trap;
    sigaction(SIGTRAP, NULL, &old_action_trap);
    if (old_action_trap.sa_sigaction) {
        previousTRAPSignalHandler = old_action_trap.sa_sigaction;
    }
}

+ (void)signalRegister {
    MMSignalRegister(SIGABRT);
    MMSignalRegister(SIGBUS);
    MMSignalRegister(SIGFPE);
    MMSignalRegister(SIGILL);
    MMSignalRegister(SIGPIPE);
    MMSignalRegister(SIGSEGV);
    MMSignalRegister(SIGSYS);
    MMSignalRegister(SIGTRAP);
}

#pragma mark - Private

#pragma mark Register Signal

static void MMSignalRegister(int signal) {
    struct sigaction action;
    action.sa_sigaction = MMSignalHandler;
    action.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&action.sa_mask);
    sigaction(signal, &action, 0);
}

#pragma mark SignalCrash Handler

static void MMSignalHandler(int signal, siginfo_t *info, void *context) {
    NSMutableString *mstr = [[NSMutableString alloc] init];
    [mstr appendString:@"Signal Exception:\n"];
    /**
     Very strange crash log from AppCenter:
     
     MMCrashSignalExceptionHandler.m, line 115
     
     MAIN THREAD - CRASHED
     libsystem_pthread.dylib    ___chkstk_darwin
     CoreFoundation             0x7ff818dd0000 + 1443179
     CoreFoundation             0x7ff818dd0000 + 185932
     Foundation                 -[NSPlaceholderString initWithFormat:locale:arguments:]
     Foundation                 +[NSString stringWithFormat:]
     Easydict                   MMSignalHandler MMCrashSignalExceptionHandler.m:115
     libsystem_platform.dylib   _sigtramp
     */
    [mstr appendString:[NSString stringWithFormat:@"Signal %@ was raised.\n", signalName(signal)]];
    [mstr appendString:@"Call Stack:\n"];

    //    void* callstack[128];
    //    int i, frames = backtrace(callstack, 128);
    //    char** strs = backtrace_symbols(callstack, frames);
    //    for (i = 0; i <frames; ++i) {
    //        [mstr appendFormat:@"%s\n", strs[i]];
    //    }

    // 这里过滤掉第一行日志
    // 因为注册了信号崩溃回调方法，系统会来调用，将记录在调用堆栈上，因此此行日志需要过滤掉
    for (NSUInteger index = 1; index < NSThread.callStackSymbols.count; index++) {
        NSString *str = [NSThread.callStackSymbols objectAtIndex:index];
        [mstr appendString:[str stringByAppendingString:@"\n"]];
    }

    [mstr appendString:@"threadInfo:\n"];
    [mstr appendString:[[NSThread currentThread] description]];

    // 保存崩溃日志到沙盒cache目录
    [MMCrashFileTool saveCrashLog:[NSString stringWithString:mstr] fileName:@"Crash(Signal)"];

    MMClearSignalRigister();

    // 调用之前崩溃的回调函数
    previousSignalHandler(signal, info, context);

    kill(getpid(), SIGKILL);
}

#pragma mark Signal To Name

static NSString *signalName(int signal) {
    NSString *signalName;
    switch (signal) {
        case SIGABRT:
            signalName = @"SIGABRT";
            break;
        case SIGBUS:
            signalName = @"SIGBUS";
            break;
        case SIGFPE:
            signalName = @"SIGFPE";
            break;
        case SIGILL:
            signalName = @"SIGILL";
            break;
        case SIGPIPE:
            signalName = @"SIGPIPE";
            break;
        case SIGSEGV:
            signalName = @"SIGSEGV";
            break;
        case SIGSYS:
            signalName = @"SIGSYS";
            break;
        case SIGTRAP:
            signalName = @"SIGTRAP";
            break;
            
        default:
            signalName = @"Unknown Signal";
            break;
    }
    return signalName;
}

#pragma mark Previous Signal

static void previousSignalHandler(int signal, siginfo_t *info, void *context) {
    SignalHandler previousSignalHandler = NULL;
    switch (signal) {
        case SIGABRT:
            previousSignalHandler = previousABRTSignalHandler;
            break;
        case SIGBUS:
            previousSignalHandler = previousBUSSignalHandler;
            break;
        case SIGFPE:
            previousSignalHandler = previousFPESignalHandler;
            break;
        case SIGILL:
            previousSignalHandler = previousILLSignalHandler;
            break;
        case SIGPIPE:
            previousSignalHandler = previousPIPESignalHandler;
            break;
        case SIGSEGV:
            previousSignalHandler = previousSEGVSignalHandler;
            break;
        case SIGSYS:
            previousSignalHandler = previousSYSSignalHandler;
            break;
        case SIGTRAP:
            previousSignalHandler = previousTRAPSignalHandler;
            break;
        default:
            break;
    }

    if (previousSignalHandler) {
        previousSignalHandler(signal, info, context);
    }
}

#pragma mark Clear

static void MMClearSignalRigister(void) {
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGTRAP, SIG_DFL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    signal(SIGSYS, SIG_DFL);
}

@end
