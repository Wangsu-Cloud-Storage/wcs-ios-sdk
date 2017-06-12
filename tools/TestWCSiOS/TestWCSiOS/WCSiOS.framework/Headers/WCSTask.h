/*
 *  Copyright (c) 2014, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import "WCSCancellationToken.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 Error domain used if there was multiple errors on <WCSTask taskForCompletionOfAllTasks:>.
 */
extern NSString *const WCSTaskErrorDomain;

/*!
 An error code used for <WCSTask taskForCompletionOfAllTasks:>, if there were multiple errors.
 */
extern NSInteger const kWCSMultipleErrorsError;

/*!
 An exception that is thrown if there was multiple exceptions on <WCSTask taskForCompletionOfAllTasks:>.
 */
extern NSString *const WCSTaskMultipleExceptionsException;

@class WCSExecutor;
@class WCSTask;

/*!
 The consumer view of a Task. A WCSTask has methods to
 inspect the state of the task, and to add continuations to
 be run once the task is complete.
 */
@interface WCSTask<__covariant ResultType> : NSObject

/*!
 A block that can act as a continuation for a task.
 */
typedef __nullable id(^WCSContinuationBlock)(WCSTask<ResultType> *task);

/*!
 Creates a task that is already completed with the given result.
 @param result The result for the task.
 */
+ (instancetype)taskWithResult:(nullable ResultType)result;

/*!
 Creates a task that is already completed with the given error.
 @param error The error for the task.
 */
+ (instancetype)taskWithError:(NSError *)error;

/*!
 Creates a task that is already completed with the given exception.
 @param exception The exception for the task.
 */
+ (instancetype)taskWithException:(NSException *)exception;

/*!
 Creates a task that is already cancelled.
 */
+ (instancetype)cancelledTask;

/*!
 Returns a task that will be completed (with result == nil) once
 all of the input tasks have completed.
 @param tasks An `NSArray` of the tasks to use as an input.
 */
+ (instancetype)taskForCompletionOfAllTasks:(nullable NSArray<WCSTask *> *)tasks;

/*!
 Returns a task that will be completed once all of the input tasks have completed.
 If all tasks complete successfully without being faulted or cancelled the result will be
 an `NSArray` of all task results in the order they were provided.
 @param tasks An `NSArray` of the tasks to use as an input.
 */
+ (instancetype)taskForCompletionOfAllTasksWithResults:(nullable NSArray<WCSTask *> *)tasks;

/*!
 Returns a task that will be completed a certain amount of time in the future.
 @param millis The approximate number of milliseconds to wait before the
 task will be finished (with result == nil).
 */
+ (instancetype)taskWithDelay:(int)millis;

/*!
 Returns a task that will be completed a certain amount of time in the future.
 @param millis The approximate number of milliseconds to wait before the
 task will be finished (with result == nil).
 @param token The cancellation token (optional).
 */
+ (instancetype)taskWithDelay:(int)millis cancellationToken:(nullable WCSCancellationToken *)token;

/*!
 Returns a task that will be completed after the given block completes with
 the specified executor.
 @param executor A WCSExecutor responsible for determining how the
 continuation block will be run.
 @param block The block to immediately schedule to run with the given executor.
 @returns A task that will be completed after block has run.
 If block returns a WCSTask, then the task returned from
 this method will not be completed until that task is completed.
 */
+ (instancetype)taskFromExecutor:(WCSExecutor *)executor withBlock:(nullable id (^)())block;

// Properties that will be set on the task once it is completed.

/*!
 The result of a successful task.
 */
@property (nullable, nonatomic, strong, readonly) ResultType result;

/*!
 The error of a failed task.
 */
@property (nullable, nonatomic, strong, readonly) NSError *error;

/*!
 The exception of a failed task.
 */
@property (nullable, nonatomic, strong, readonly) NSException *exception;

/*!
 Whether this task has been cancelled.
 */
@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;

/*!
 Whether this task has completed due to an error or exception.
 */
@property (nonatomic, assign, readonly, getter=isFaulted) BOOL faulted;

/*!
 Whether this task has completed.
 */
@property (nonatomic, assign, readonly, getter=isCompleted) BOOL completed;

/*!
 Enqueues the given block to be run once this task is complete.
 This method uses a default execution strategy. The block will be
 run on the thread where the previous task completes, unless the
 the stack depth is too deep, in which case it will be run on a
 dispatch queue with default priority.
 @param block The block to be run once this task is complete.
 @returns A task that will be completed after block has run.
 If block returns a WCSTask, then the task returned from
 this method will not be completed until that task is completed.
 */
- (WCSTask *)continueWithBlock:(WCSContinuationBlock)block;

/*!
 Enqueues the given block to be run once this task is complete.
 This method uses a default execution strategy. The block will be
 run on the thread where the previous task completes, unless the
 the stack depth is too deep, in which case it will be run on a
 dispatch queue with default priority.
 @param block The block to be run once this task is complete.
 @param cancellationToken The cancellation token (optional).
 @returns A task that will be completed after block has run.
 If block returns a WCSTask, then the task returned from
 this method will not be completed until that task is completed.
 */
- (WCSTask *)continueWithBlock:(WCSContinuationBlock)block cancellationToken:(nullable WCSCancellationToken *)cancellationToken;

/*!
 Enqueues the given block to be run once this task is complete.
 @param executor A WCSExecutor responsible for determining how the
 continuation block will be run.
 @param block The block to be run once this task is complete.
 @returns A task that will be completed after block has run.
 If block returns a WCSTask, then the task returned from
 this method will not be completed until that task is completed.
 */
- (WCSTask *)continueWithExecutor:(WCSExecutor *)executor withBlock:(WCSContinuationBlock)block;
/*!
 Enqueues the given block to be run once this task is complete.
 @param executor A WCSExecutor responsible for determining how the
 continuation block will be run.
 @param block The block to be run once this task is complete.
 @param cancellationToken The cancellation token (optional).
 @returns A task that will be completed after block has run.
 If block returns a WCSTask, then the task returned from
 his method will not be completed until that task is completed.
 */
- (WCSTask *)continueWithExecutor:(WCSExecutor *)executor
                           block:(WCSContinuationBlock)block
               cancellationToken:(nullable WCSCancellationToken *)cancellationToken;

/*!
 Identical to continueWithBlock:, except that the block is only run
 if this task did not produce a cancellation, error, or exception.
 If it did, then the failure will be propagated to the returned
 task.
 @param block The block to be run once this task is complete.
 @returns A task that will be completed after block has run.
 If block returns a WCSTask, then the task returned from
 this method will not be completed until that task is completed.
 */
- (WCSTask *)continueWithSuccessBlock:(WCSContinuationBlock)block;

/*!
 Identical to continueWithBlock:, except that the block is only run
 if this task did not produce a cancellation, error, or exception.
 If it did, then the failure will be propagated to the returned
 task.
 @param block The block to be run once this task is complete.
 @param cancellationToken The cancellation token (optional).
 @returns A task that will be completed after block has run.
 If block returns a WCSTask, then the task returned from
 this method will not be completed until that task is completed.
 */
- (WCSTask *)continueWithSuccessBlock:(WCSContinuationBlock)block cancellationToken:(nullable WCSCancellationToken *)cancellationToken;

/*!
 Identical to continueWithExecutor:withBlock:, except that the block
 is only run if this task did not produce a cancellation, error, or
 exception. If it did, then the failure will be propagated to the
 returned task.
 @param executor A WCSExecutor responsible for determining how the
 continuation block will be run.
 @param block The block to be run once this task is complete.
 @returns A task that will be completed after block has run.
 If block returns a WCSTask, then the task returned from
 this method will not be completed until that task is completed.
 */
- (WCSTask *)continueWithExecutor:(WCSExecutor *)executor withSuccessBlock:(WCSContinuationBlock)block;

/*!
 Identical to continueWithExecutor:withBlock:, except that the block
 is only run if this task did not produce a cancellation, error, or
 exception. If it did, then the failure will be propagated to the
 returned task.
 @param executor A WCSExecutor responsible for determining how the
 continuation block will be run.
 @param block The block to be run once this task is complete.
 @param cancellationToken The cancellation token (optional).
 @returns A task that will be completed after block has run.
 If block returns a WCSTask, then the task returned from
 this method will not be completed until that task is completed.
 */
- (WCSTask *)continueWithExecutor:(WCSExecutor *)executor
                    successBlock:(WCSContinuationBlock)block
               cancellationToken:(nullable WCSCancellationToken *)cancellationToken;

/*!
 Waits until this operation is completed.
 This method is inefficient and consumes a thread resource while
 it's running. It should be avoided. This method logs a warning
 message if it is used on the main thread.
 */
- (void)waitUntilFinished;

@end

NS_ASSUME_NONNULL_END
