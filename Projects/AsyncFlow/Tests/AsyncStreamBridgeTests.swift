//
//  AsyncStreamBridgeTests.swift
//  AsyncFlowTests
//
//  Created by 정준영 on 2025. 12. 29.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("AsyncPassthroughSubject Tests")
struct AsyncPassthroughSubjectTests {
    // MARK: - Basic Functionality Tests

    @Test("단일 구독자가 값을 정상적으로 수신하는지 확인")
    @MainActor
    func singleSubscriber() async {
        let subject = AsyncPassthroughSubject<Int>()
        let stream = subject.stream

        let task = Task {
            var receivedValues: [Int] = []
            for await value in stream {
                receivedValues.append(value)
            }
            return receivedValues
        }

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.finish()

        let receivedValues = await task.value

        #expect(receivedValues == [1, 2, 3])
    }

    @Test("빈 스트림을 finish 하면 빈 배열을 반환")
    @MainActor
    func emptyStream() async {
        let subject = AsyncPassthroughSubject<Int>()
        let stream = subject.stream

        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
            }
            return values
        }

        subject.finish()

        let result = await task.value
        #expect(result.isEmpty)
    }

    @Test("구독 전에 send한 값은 받지 못함")
    @MainActor
    func sendBeforeSubscription() async {
        let subject = AsyncPassthroughSubject<Int>()

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
        #expect(result == [3])
    }

    // MARK: - Multicast Tests

    @Test("다중 구독자(Multicast)가 값을 모두 수신하는지 확인")
    @MainActor
    func multipleSubscribers() async {
        let subject = AsyncPassthroughSubject<String>()

        let stream1 = subject.stream
        let stream2 = subject.stream

        let task1 = Task<[String], Never> {
            var values: [String] = []
            for await value in stream1 {
                values.append(value)
            }
            return values
        }

        let task2 = Task<[String], Never> {
            var values: [String] = []
            for await value in stream2 {
                values.append(value)
            }
            return values
        }

        subject.send("A")
        subject.send("B")
        subject.finish()

        let result1 = await task1.value
        let result2 = await task2.value

        #expect(result1 == ["A", "B"])
        #expect(result2 == ["A", "B"])
    }

    @Test("여러 구독자가 독립적으로 동작하는지 확인")
    @MainActor
    func independentSubscribers() async {
        let subject = AsyncPassthroughSubject<Int>()

        let stream1 = subject.stream
        let stream2 = subject.stream
        let stream3 = subject.stream

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
                if values.count == 1 { break }
            }
            return values
        }

        let task3 = Task {
            var values: [Int] = []
            for await value in stream3 {
                values.append(value)
            }
            return values
        }

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.finish()

        let (result1, result2, result3) = await (task1.value, task2.value, task3.value)

        #expect(result1 == [1, 2])
        #expect(result2 == [1])
        #expect(result3 == [1, 2, 3])
    }

    // MARK: - Cancellation Tests

    @Test("구독 취소 시 다른 구독자에게 영향이 없는지 확인")
    @MainActor
    func subscriptionCancellation() async {
        let subject = AsyncPassthroughSubject<Int>()
        let stream1 = subject.stream
        let stream2 = subject.stream

        let task1 = Task<[Int], Never> {
            var values: [Int] = []
            for await value in stream1 {
                values.append(value)
                break
            }
            return values
        }

        let task2 = Task<[Int], Never> {
            var values: [Int] = []
            for await value in stream2 {
                values.append(value)
            }
            return values
        }

        subject.send(1)
        subject.send(2)
        subject.finish()

        let result1 = await task1.value
        let result2 = await task2.value

        #expect(result1 == [1])
        #expect(result2 == [1, 2])
    }

    @Test("중간에 구독 취소 후 새로운 구독이 정상 동작하는지 확인")
    @MainActor
    func cancelAndResubscribe() async {
        let subject = AsyncPassthroughSubject<Int>()

        // 첫 번째 구독
        let stream1 = subject.stream
        let task1 = Task {
            var values: [Int] = []
            for await value in stream1 {
                values.append(value)
            }
            return values
        }

        subject.send(1)
        try? await Task.sleep(nanoseconds: 10_000_000)

        task1.cancel()
        try? await Task.sleep(nanoseconds: 10_000_000)

        // 두 번째 구독
        let stream2 = subject.stream
        let task2 = Task {
            var values: [Int] = []
            for await value in stream2 {
                values.append(value)
                if values.count == 2 { break }
            }
            return values
        }

        subject.send(2)
        subject.send(3)

        let result2 = await task2.value
        #expect(result2 == [2, 3])
    }

    // MARK: - Finish Tests

    @Test("finish 호출 후 새로운 구독자는 즉시 종료됨")
    @MainActor
    func finishBeforeNewSubscription() async {
        let subject = AsyncPassthroughSubject<Int>()

        subject.send(1)
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
        #expect(result.isEmpty)
    }

    @Test("finish는 모든 구독자를 종료시킴")
    @MainActor
    func finishAllSubscribers() async {
        let subject = AsyncPassthroughSubject<String>()

        let stream1 = subject.stream
        let stream2 = subject.stream

        let task1 = Task {
            var values: [String] = []
            for await value in stream1 {
                values.append(value)
            }
            return values
        }

        let task2 = Task {
            var values: [String] = []
            for await value in stream2 {
                values.append(value)
            }
            return values
        }

        subject.send("A")
        subject.send("B")
        subject.finish()

        let (result1, result2) = await (task1.value, task2.value)

        #expect(result1 == ["A", "B"])
        #expect(result2 == ["A", "B"])
    }

    // MARK: - Performance Tests

    @Test("대량의 값을 빠르게 방출해도 정상 동작하는지 확인")
    @MainActor
    func highVolumeSend() async {
        let subject = AsyncPassthroughSubject<Int>()
        let stream = subject.stream

        let task = Task {
            var values: [Int] = []
            for await value in stream {
                values.append(value)
            }
            return values
        }

        let count = 1000
        for i in 0 ..< count {
            subject.send(i)
        }
        subject.finish()

        let result = await task.value
        #expect(result.count == count)
        #expect(result == Array(0 ..< count))
    }

    @Test("여러 구독자가 대량의 값을 동시에 받을 수 있는지 확인")
    @MainActor
    func multicastHighVolume() async {
        let subject = AsyncPassthroughSubject<Int>()

        let streams = (0 ..< 5).map { _ in subject.stream }

        let tasks = streams.map { stream in
            Task {
                var values: [Int] = []
                for await value in stream {
                    values.append(value)
                }
                return values
            }
        }

        let count = 100
        for i in 0 ..< count {
            subject.send(i)
        }
        subject.finish()

        let results = await withTaskGroup(of: [Int].self) { group in
            for task in tasks {
                group.addTask { await task.value }
            }

            var allResults: [[Int]] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }

        for result in results {
            #expect(result.count == count)
            #expect(result == Array(0 ..< count))
        }
    }
}
