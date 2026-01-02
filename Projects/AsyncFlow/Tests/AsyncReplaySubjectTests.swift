//
//  AsyncReplaySubjectTests.swift
//  AsyncFlowTests
//
//  Created by jimmy on 2026. 1. 1.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("AsyncReplaySubject Tests")
struct AsyncReplaySubjectTests {
    // MARK: - Basic Buffering Tests

    @Test("ReplaySubject buffers one value by default")
    @MainActor
    func bufferOneValue() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 1)

        // When
        subject.send(1)
        subject.send(2)
        subject.send(3)

        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
                if values.count == 1 { break }
            }
            return values
        }

        let result = await task.value

        // Then - 마지막 값만 수신
        #expect(result == [3])
    }

    @Test("ReplaySubject buffers multiple values")
    @MainActor
    func bufferMultipleValues() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 3)

        // When
        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)

        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
                if values.count == 3 { break }
            }
            return values
        }

        let result = await task.value

        // Then - 마지막 3개 값 수신
        #expect(result == [2, 3, 4])
    }

    @Test("ReplaySubject with zero buffer size")
    @MainActor
    func zeroBufferSize() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 0)

        // When
        subject.send(1)
        subject.send(2)

        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
                if values.count == 1 { break }
            }
            return values
        }

        subject.send(3)

        let result = await task.value

        // Then - 버퍼 없으므로 구독 후 값만 수신
        #expect(result == [3])
    }

    // MARK: - Multiple Subscribers with Buffer

    @Test("Multiple subscribers receive buffered values")
    @MainActor
    func multipleSubscribersReceiveBuffer() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 2)

        // When
        subject.send(1)
        subject.send(2)
        subject.send(3)

        let stream1 = subject.stream
        let stream2 = subject.stream

        let task1 = Task {
            var values: [Int] = []
            for await value in stream1 {
                values.append(value)
                if values.count == 2 { break }
            }
            return values
        }

        let task2 = Task {
            var values: [Int] = []
            for await value in stream2 {
                values.append(value)
                if values.count == 2 { break }
            }
            return values
        }

        let (result1, result2) = await (task1.value, task2.value)

        // Then - 둘 다 버퍼된 마지막 2개 값 수신
        #expect(result1 == [2, 3])
        #expect(result2 == [2, 3])
    }

    @Test("Late subscriber receives buffer")
    @MainActor
    func lateSubscriberReceivesBuffer() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 3)

        // When
        subject.send(1)
        subject.send(2)
        subject.send(3)

        try? await Task.sleep(nanoseconds: 10_000_000)

        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
                if values.count == 3 { break }
            }
            return values
        }

        let result = await task.value

        // Then
        #expect(result == [1, 2, 3])
    }

    // MARK: - Buffer + Live Values

    @Test("Subscriber receives buffer then live values")
    @MainActor
    func bufferThenLiveValues() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 2)

        // When
        subject.send(1)
        subject.send(2)

        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
                if values.count == 4 { break }
            }
            return values
        }

        try? await Task.sleep(nanoseconds: 10_000_000)

        subject.send(3)
        subject.send(4)

        let result = await task.value

        // Then - 버퍼 2개 + 라이브 2개
        #expect(result == [1, 2, 3, 4])
    }

    // MARK: - Finish Tests

    @Test("Finish with buffer")
    @MainActor
    func finishWithBuffer() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 2)

        // When
        subject.send(1)
        subject.send(2)
        subject.finish()

        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
            }
            return values
        }

        let result = await task.value

        // Then - finish 후 구독해도 빈 배열
        #expect(result.isEmpty)
    }

    @Test("Finish clears buffer")
    @MainActor
    func finishClearsBuffer() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 3)

        // When
        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.finish()

        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
            }
            return values
        }

        let result = await task.value

        // Then
        #expect(result.isEmpty)
    }

    @Test("Send after finish is ignored")
    @MainActor
    func sendAfterFinishIgnored() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 2)

        // When
        subject.send(1)
        subject.finish()
        subject.send(2)

        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
            }
            return values
        }

        let result = await task.value

        // Then
        #expect(result.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("Empty buffer subscription")
    @MainActor
    func emptyBufferSubscription() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 2)

        // When
        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
                if values.count == 1 { break }
            }
            return values
        }

        try? await Task.sleep(nanoseconds: 10_000_000)

        subject.send(1)

        let result = await task.value

        // Then
        #expect(result == [1])
    }

    @Test("Very large buffer size")
    @MainActor
    func veryLargeBuffer() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 100)

        // When
        for i in 0 ..< 50 {
            subject.send(i)
        }

        let stream = subject.stream
        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
                if values.count == 50 { break }
            }
            return values
        }

        let result = await task.value

        // Then - 모든 값이 버퍼에 저장되어 수신됨
        #expect(result.count == 50)
        #expect(result == Array(0 ..< 50))
    }

    @Test("Subscription during active send")
    @MainActor
    func subscriptionDuringActiveSend() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 1)

        // When
        subject.send(1)

        let stream = subject.stream

        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
                if values.count == 2 { break }
            }
            return values
        }

        subject.send(2)

        let result = await task.value

        // Then - 버퍼 1개 + 새 값 1개
        #expect(result == [1, 2])
    }

    // MARK: - Concurrent Scenarios

    @Test("Multiple concurrent sends and subscriptions")
    @MainActor
    func concurrentSendsAndSubscriptions() async {
        // Given
        let subject = AsyncReplaySubject<Int>(bufferSize: 5)

        // When
        let sendTask = Task {
            for i in 0 ..< 10 {
                subject.send(i)
                try? await Task.sleep(nanoseconds: 1_000_000)
            }
        }

        let subscribeTask1 = Task {
            var values: [Int] = []
            for await value in subject.stream {
                values.append(value)
                if values.count == 5 { break }
            }
            return values
        }

        try? await Task.sleep(nanoseconds: 5_000_000)

        let subscribeTask2 = Task {
            var values: [Int] = []
            for await value in subject.stream {
                values.append(value)
                if values.count == 5 { break }
            }
            return values
        }

        let (result1, result2) = await (subscribeTask1.value, subscribeTask2.value)
        await sendTask.value

        // Then - 두 구독자 모두 값을 받음
        #expect(result1.count == 5)
        #expect(result2.count == 5)
    }

    @Test("FlowStepper integration with initialStep")
    @MainActor
    func flowStepperIntegration() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = TestStepperWithInitial()

        var subscribed = false
        var readyCalled = false
        stepper.onObservationStart = { subscribed = true }
        stepper.onReady = { readyCalled = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed && readyCalled }
        await Test.waitUntil { flow.navigateCallCount >= 1 }

        // Then - initialStep이 자동으로 방출됨
        #expect(flow.navigateCallCount == 1)
        #expect((flow.lastStep as? TestStep) == .initial)
    }
}

// MARK: - Test Helper

@MainActor
final class TestStepperWithInitial: FlowStepper {
    let steps = AsyncReplaySubject<Step>(bufferSize: 1)

    var initialStep: Step {
        TestStep.initial
    }

    var onObservationStart: (() -> Void)?
    var onReady: (() -> Void)?

    func readyToEmitSteps() {
        onObservationStart?()
        onReady?()
    }
}
